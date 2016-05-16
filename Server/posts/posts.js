
/*
 * Handles post operation from clients
 * Copyright Jinhua Wang, 2015
 * The MIT License (MIT)
 * Copyright (c) <2015> <Jinhua Wang>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 * documentation files (the "Software"), to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
 * and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all copies or substantial portions
 * of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED
 * TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 * CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

/*
 *   Error table:
 *    s01 => server error  (^_^)
 *    p01 => course_code or course_content empty
 *    p02 => Max character count for post reached
 *    p03 => User not found
 *    p04 => User not verified
 *    p05 => University not found
 *    p06 => ownership error
 *    p07 => no image type specified
 *    p08 => file type wrong
 *    p09 => no image found on server
 *    p11 => direction not supplied
 *    p12 => no new post
 *    p13 => no next posts
 *    p14 => university not found
 *    p15 => book condition code not found
 *    p16 => multi action: no more posts found
 *    p17 => no post found
 *    p18 => modify post: must specify at least one argument to modify
 *    n01 => notify: user not found
 */

var redis = require('redis');
var debug = require('debug')('posts');
var multer  = require('multer');//multer module is for file uploads
var Magic = require('mmmagic').Magic;//check the magic number of the image, only JPEG is acceptable
var config = require('../config');
var fs = require('fs');
var university = require('../university.js');
var mongoose = require('mongoose');
var user = require('../user/user.js');
var cron = require('cron');
//postmark is used here to send verification emails
var postmark = require("postmark");

//create redis client
var client = redis.createClient();

client.on("error", function (err) {
          debug("Error " + err);
});

//configure multer image upload
var storage = multer.memoryStorage();

//new magic object
var magic = new Magic();

//connect mongoose to database
if(!mongoose.connection.readyState)
mongoose.connect(config.database, config.mongodb_opt);

//postmark for sending emails
var pmark = new postmark.Client(config.POST_MARK_TOKEN);

module.exports = posts = function(){
        var id_count_exists = client.exists('next_post_id', function(err, doesExist){
            if(err){
                debug(err);
                return;
            }
            if(!doesExist){
            //set default post id
                client.set('next_post_id','100', function(err, status){
                          if(err){
                            debug(err);
                          }
                });
            }
        });
};

//not authenticated, for demo purposes only. pop 20 new posts from overall university timeline
posts.prototype.nonAuthPosts = function(req, res, next){
    client.ZRANGE('university:all', '0' , '20', function(err, reply){
                  if(err) return res.json({success:false, message:"server error", code:"s01"});
                  if(!reply){
                    return res.json({success:false, message:'no new posts', code:'p12'});
                  }
                  var json_rep = {};
                  for(var i=0;i<reply.length;i++){
                    json_rep[reply[i]] = {};
                  }
                  if(!req.unibook){
                    req.unibook = {};
                  }
                  req.unibook.unibookJsonRaw = json_rep;
                  next();
                  });
};

//non-auth version of the postmultihelper - does not return some information such as user's email
//prerequisite: nonAuthPosts
posts.prototype.nonAuthPostMultiHelper = function(req, res, next){
    var json_raw = req.unibook.unibookJsonRaw;
    var json_send = [];
    //atomic operation multi
    multi = client.multi();
    for(var key in json_raw){
        multi.hgetall("post:"+key);
    }
    multi.exec(function(err, replies){
               if(err){
                return res.json({success:false, message:"server error", code:"s01"});
               }
               if(!replies){
                return res.json({success:false, message:"no more mosts", code:"p16"});
               }
               for(var i=0;i<replies.length;i++){
                   //if the reply is empty, ignore
                   if(!replies[i]){
                    continue;
                   }
                   //add and convert the time
                   if(replies[i].timestamp_mil){
                    replies[i].time = timeHelper(replies[i].timestamp_mil);
                   }
                   //organize the results to send
                   var space = " ";
                   json_send[i] = {
                       post_id:"1",
                       name:"[Name Hidden]",
                       email:"[Email Hidden]",
                       front_cover:space,
                       isbn_page:space,
                       author:replies[i]['username'],
                       university:replies[i]['university'],
                       post_content:replies[i]['post_content'],
                       course_code:replies[i]['course_code'],
                       course_title:replies[i]['course_title'],
                       professor:replies[i]['professor'],
                       preferred_price:replies[i]['preferred_price'],
                       book_condition:replies[i]['book_condition'],
                       sold:replies[i]['sold'],
                       timestamp_mil:replies[i]['timestamp_mil'],
                       time:timeHelper(replies[i]['timestamp_mil']),
                   }
               
               }
               //send the reply in json
               return res.json({success:true, postObject:json_send});
    });
};

//count the number of interested buyers in the post
posts.prototype.nonAuthcountInterestedBuyers = function(req, res, next){
    client.scard("buyPost:"+req.params.postid, function(err, reply){
        if(err) return res.json({success:false, message:"get interest count false, server error", code:"s01"});
        if(!reply) return res.json({success:true, count:0});
        return res.json({success:true, count:parseInt(reply, 10)});
    });
};

/*Methods that requires authentication*/

//new post
//Prerequisite: bodyParser.json(), tokenMiddleware, getUserUniMiddleware
/*
 * {
 *   post_content:String, //optional, < 120 chars
 *   course_code:String,  //mandatory < 20 chars
 *   course_title:String, //mandatory < 60 chars
 *   professor: String,   //optional  < 60 chars
 *   preferred_price:Integer//mandatory
 *   book_condition: String, //mandatory
 * }
 */
posts.prototype.newPost = function(req, res, next){
    //authenticated
    var username = req.decoded.username;
    var course_code = req.body.course_code;
    var post_content = req.body.post_content;
    var course_title = req.body.course_title;
    var professor = req.body.professor;
    var book_condition = '';
    var preferred_price = parseInt(req.body.preferred_price, 10);
    if(!(course_code)||!(course_title)||!(req.body.book_condition)||!(req.body.preferred_price)||isNaN(preferred_price)){
        return res.json({success:false, message:"course_code or course_content or book_condition empty", code:"p01"});
    }
    switch(req.body.book_condition){
        case 'brand_new':
            book_condition = 'brand_new';
            break;
        //book used but condition still good
        case 'used_good':
            book_condition = 'used_good';
            break;
        //book used with some damage
        case 'used_damage':
            book_condition = 'used_damage';
            break;
        default:
            return res.json({success:false, message:'book condition code wrong', code:'p15'})
    }
    if(charL(post_content)>120 || charL(course_code)>20 || charL(course_title)>60 || charL(professor)>60)
        return res.json({success:false, message:"Max char count reached", code:"p02"});
    //increase the new post id
    var timestamp = new Date().getTime();
    client.incr('next_post_id', function(err, reply) {
                if(err){
                    debug(err);
                    return res.json({success:false, message:"new post failed, server error", code:"s01"});
                }
                client.hmset("post:"+reply, "username", username, "email", req.unibook.UserUnimail, "university", req.unibook.UserUniname, "post_content", post_content, "course_code", course_code, "course_title", course_title, "professor", professor, "preferred_price", preferred_price,"front_cover", "pending", "isbn_page", "pending", "book_condition", book_condition, "sold", "false", "timestamp_mil", timestamp, function(err, reply_post){
                         if(err){
                            debug(err);
                            return res.json({success:false, message:"new post failed, server error", code:"s01"});
                         }
                         if(!reply_post){
                             return res.json({success:false, message:"new post failed, server error", code:"s01"});
                         }
                         req.body.post_id = reply;
                         req.unibook.uniNewpostTime = timestamp;
                         next();
                });
                
    });
};

//return the length of the string
var charL = function (str){
    //if void return 0
    if(!str) return 0;
    var words = str.length;
    return words;
};

//Feed the post to news in a university
//Also publish the post using redis
//Prerequisite: bodyParser.json(), tokenMiddleware, getUserUniMiddleware, newPost
posts.prototype.postFeed = function(req, res, next){
     //timestamp in zscore should be the same as the timestamp upon which the post was created
     var timestamp = req.unibook.uniNewpostTime;
    
     //get the university name
     var universityName = req.unibook.UserUniname;
     if(!universityName){
        return res.json({success:false, message:"Error Adding Post, University not found", code:'p05'});
     }
     //now push the post to the redis
     //user's personal timeline
     client.zadd([req.decoded.username+':posts', timestamp, req.body.post_id], function(err, response){
        if(err)
            debug(err);
     });
     //news feed - we only keep 1000000 posts in the news feed
     //using timestamp in milliseconds as the score
     client.zadd(['university:'+universityName, timestamp, req.body.post_id], function(err, response){
         if(err){
            debug(err);
         }
     });
     client.zadd(['university:all', timestamp, req.body.post_id], function(err, response){
         if(err){
            debug(err);
         }
     });
     //publish the posts to subscribers
     client.publish('university:'+universityName, req.body.post_id);
     client.publish('university:all', req.body.post_id);
     res.json({success:true, post_id:req.body.post_id});
};

//this cron job operates everyday at 0330 AM
var cronJob = cron.job("00 30 03 * * 1-5", function(){
                       // perform operation e.g. GET request http.get() etc.
                       trimList();
                       debug("trimming list");
});
cronJob.start();

//cronjob to trim post list - we only keep 1000000 posts in the redis news feed
var trimList = function(){
    for (var key in university){
        var count = client.ZCOUNT('university'+university[key], '-inf', '+inf');
        if(count>config.MAX_POST_PER_UNIVERSITY){
            client.ZREMRANGEBYRANK('university'+university[key], 0, count-config.MAX_POST_PER_UNIVERSITY);
        }
    }
    var count_all = count = client.ZCOUNT('university:all', '-inf', '+inf');
    if(count_all>config.MAX_POST_ALL){
        client.ZREMRANGEBYRANK('university:all', 0, count_all - config.MAX_POST_ALL);
    }
}


//process the image upload, one at a time
posts.prototype.ownershipCheck = function(req, res, next){
    //verify that the post belongs to the user
    client.hget("post:"+req.params.postid, 'username', function(err, reply){
                if(err){
                    return res.json({success:false, message:"new post img failed, server error", code:"s01"});
                }
                if(!reply||reply!=req.decoded.username){
                    return res.json({success:false, message:"new post img failed, ownership error", code:"p06"});
                }
                next();
    });
};

//multer upload
posts.prototype.multer_profile_upload = multer({ storage: storage , limits: {fileSize: config.MAX_FILE_SIZE_FOR_BOOK_IMAGE_UPLOAD},
                                               }).single('userfile');

//check the image type
//prerequistites: tokenMiddleware, ownershipCheck, multer_profile_upload
posts.prototype.imgTypeCheck = function (req, res, next){
        var imgTypeRaw = req.params.imgType;
        var imgType = '';
        if(imgTypeRaw=='front_cover')
            req.params.imgType = imgType = 'front_cover';
        else if(imgTypeRaw=='isbn_page')
            req.params.imgType = imgType = 'isbn_page';
        else return res.json({success:false, message:'no image type specified', code:'p07'});
        //check for ip address
        var ip = req.headers['x-forwarded-for'] || req.connection.remoteAddress;
            magic.detect(req.file.buffer, function(err, result) {
                 if (err) {
                     debug(err);
                     return res.status(403).json({ success: false, message: 'Upload failed. Server error.', code: 's01' });
                 };
                 var arr = result.split(',');
                 //only jpeg file type is permitted
                 if(arr[0]=='JPEG image data'){
                 //since it is run after the tokenMiddleware, we consider the user name is in the req object and has been authenticated
                 fs.writeFile("../files/book_images/"+req.params.postid+"_"+imgType+".jpg", req.file.buffer, function(err) {
                              if(err) {
                                debug(err);
                                return res.status(403).json({ success: false, message: 'Upload img failed. Server error.', code: 's01' });
                              }
                              //move on
                              next();
                     });
                 }
                 else {
                    debug(ip+' is sending wrong file type');
                    return res.status(403).json({success:false, message:'file type wrong', code:'p08'});;
                 }
                 });
};

//prerequistites: tokenMiddleware, ownershipCheck, multer_profile_upload, imgTypeCheck
posts.prototype.logFileToRedis = function(req, res, next){
    var url = config.site_url+'/post_img/'+req.params.postid+'/'+ req.params.imgType;
    if(req.params.imgType=='front_cover'){
        client.hmset('post:'+req.params.postid, 'front_cover', url, function(err, reply){
             if(err){
                debug(err);
                return res.status(403).json({ success: false, message: 'Upload img failed. Server error.', code: 's01' });
             }
             if(!reply){
                return res.status(403).json({ success: false, message: 'Upload img failed. no post found', code: 'p17' });
             }
             req.unibook.postImgUrl = url;
             next();
        });
    }
    else if(req.params.imgType=='isbn_page'){
        client.hmset('post:'+req.params.postid, 'isbn_page', url, function(err, reply){
             if(err){
                debug(err);
                return res.status(403).json({ success: false, message: 'Upload img failed. Server error.', code: 's01' });
             }
             if(!reply){
                return res.status(403).json({ success: false, message: 'Upload img failed. no post found', code: 'p17' });
             }
             req.unibook.postImgUrl = url;
             next();
                     
        });
    }
};

//prerequisite: none (so far)
posts.prototype.sendPostImg = function(req, res, next){
    var post_id = req.params.post_id;
    var img_type = req.params.img_type;
    res.sendFile(post_id+"_"+img_type+".jpg", { root: path.join(__dirname, '../files/book_images/')}, function(err){
        if(err)
            return res.json({success: false, message: 'No image found on server' , code:'p09'});
    });
};

//get post by postid
//prerequisites: tokenMiddleware
posts.prototype.getPost = function(req, res, next){
    var post_id = req.params.postid;
    client.hgetall('post:'+post_id, function(err, obj){
                   if(err){
                    debug(er);
                    return res.status(403).json({ success: false, message: 'Get post failed. Server error.', code: 's01' });
                   }
                   if(!obj){
                    return res.json({success: false, message: 'Get post failed, post id not found' , code:'p10'});
                   }
                   var postObj = {
                       author:obj['username'],
                       email:replies[i]['email'],
                       university:replies[i]['university'],
                       post_content:obj['post_content'],
                       course_code:obj['course_code'],
                       course_title:obj['course_title'],
                       professor:obj['professor'],
                       preferred_price:obj[i]['preferred_price'],
                       front_cover:obj['front_cover'],
                       isbn_page:obj['isbn_page'],
                       book_condition:obj['book_condition'],
                       sold:obj['sold'],
                       timestamp_mil:obj['timestamp_mil'],
                       time:timeHelper(obj['timestamp_mil']),
                   };
                   return res.json({success:true, post:postObj});
    });
};

//format the time - convert timestamp from milliseconds to date hour/min/sec
var timeHelper = function(timestamp_millisec){
    var date = new Date(parseInt(timestamp_millisec));
    var str = date.getFullYear() + "-" + (date.getMonth() + 1) + "-" + date.getDate() + " " +  date.getHours() + ":" + date.getMinutes();
    return str;
};


//prerequisites: tokenMiddleware
/* @params: direction: @String, 'up' for new posts, 'down' for old posts
 *          clientTimestamp: @String, lastest/oldest timestamp that the client has
 *          clientRepeatPost: @String, the number of post with the clientTimestamp on client's side
 *          clientPostid: the postid that the client already has (if direction is up, this is the lastestid, if direction is down, this is
 *          the lastest id)
 * @return: [{}] json array of post id, 10 results
 */

//get the historical posts of user by username
posts.prototype.getPostByUsername = function(req, res, next){
    var username = req.decoded.username;
    //construct the object to respond to client
    var json_rep = {};
    //get the new post (top 20 records)
    client.ZRANGE(username+':posts', 0, -1, function(err, reply){
                  if(err) return res.json({success:false, message:"server error", code:"s01"});
                  if(!reply){
                    return res.json({success:false, message:'no new posts', code:'p12'});
                  }
                  for(var i=0;i<reply.length;i++){
                    json_rep[reply[i]] = {};
                  }
                  req.unibook.unibookJsonRaw = json_rep;
                  //postMultiHelper Middleware
                  next();
    });
};

//prerequisites: tokenMiddleware
/* @params: direction: @String, 'up' for new posts, 'down' for old posts
 *          clientTimestamp: @String, lastest/oldest timestamp that the client has
 *          clientRepeatPost: @String, the number of post with the clientTimestamp on client's side
 *          clientPostid: the postid that the client already has (if direction is up, this is the lastestid, if direction is down, this is
 *          the oldesst id)
 *          uniDomain: the domain of the university
 * @return: [{}] json array of post id, 10 results
 */
//get the post feed of a university
posts.prototype.getPostsUni = function(req, res, next){
    var uniDomain = req.body.uniDomain;
    var universityName = university[uniDomain];
    var clientTimestamp = req.body.clientTimestamp;
    var direction = req.body.direction;
    var clientRepeatPost = req.body.clientRepeatPost;//OFFSET
    var clientPostid = req.body.clientPostid;
    if(!universityName){
        return res.json({success:false, message:"university not found", code:'p14'});
    }
    //construct the object to respond to client
    var json_rep = {};
    //get the newest posts
    if(direction=='up'||clientTimestamp==0||clientPostid==0){
        //get the new post (top 20 records)
        debug(universityName);
        client.ZRANGE('university:'+universityName, -1-config.PAGINATION, -1, function(err, reply){
            if(err) return res.json({success:false, message:"refresh failed, server error", code:"s01"});
            if(!reply){
                return res.json({success:false, message:'no new posts', code:'p12'});
            }
            if(!(containsArr(reply, clientPostid))){
                for(var i=0;i<reply.length;i++){
                      json_rep[reply[i]] = {};
                }
                req.unibook.unibookJsonRaw = json_rep;
                //postMultiHelper Middleware
                next();
            }
              //the client post id is in the post reply
            else {
              var indexOfPost = reply.indexOf(clientPostid);
              //include the repeated postid in the response, so that the client knows there is one post repeating
              for(var i = indexOfPost; i<reply.length;i++){
                      json_rep[reply[i]] = {};
              }
              req.unibook.unibookJsonRaw = json_rep;
              //postMultiHelper Middleware
              next();
            }
        });
    }
    //get the next page
    else if(direction=='down'){
        client.ZRANGEBYSCORE('university:'+universityName, '-inf', clientTimestamp, 'LIMIT', clientRepeatPost, config.PAGINATION, function(err, reply){
                if(err){
                 debug(err);
                 return res.json({success:false, message:"next page failed, server error", code:"s01"});
                }
                if(!reply){
                 return res.json({success:false, message:'no next posts', code:'p13'});
                }
                for(var i=0;i<reply.length;i++){
                 json_rep[reply[i]] = {};
                }
                req.unibook.unibookJsonRaw = json_rep;debug(json_rep);
                 //postMultiHelper Middleware
                next();
            });
    }
    else res.json({success:false, message:"must supply direction!", code:'p11'});
};

//check if an array contains the element
//@param: arr: the array to check
//        val: the value
var containsArr = function(arr,val){
    for(var i=0;i<arr.length;i++){
        if(arr[i]==val) return true;
    }
    return false;
}

/*
 * middleware to parse postid and return post objects
 * req.unibook.unibookJsonRaw is the post id object to be parsed
 * Prerequisite: tokenMiddleware, getPostsUni/getPostByUsername
 */
posts.prototype.postMultiHelper = function(req, res, next){
    var json_raw = req.unibook.unibookJsonRaw;
    var json_send = [];
    var id_arr = [];
    //atomic operation multi
    multi = client.multi();
    var m=0;
    for(var key in json_raw){
        multi.hgetall("post:"+key);
        id_arr[m] = key;
        m++;
    }
    multi.exec(function(err, replies){
       if(err){
        return res.json({success:false, message:"server error", code:"s01"});
       }
       if(!replies){
        return res.json({success:false, message:"no more mosts", code:"p16"});
       }
       for(var i=0;i<replies.length;i++){
           //if the reply is empty, ignore
           if(!replies[i]){
               continue;
           }
            //add and convert the time
           if(replies[i].timestamp_mil){
               replies[i].time = timeHelper(replies[i].timestamp_mil);
           }
           //organize the results to send
           json_send[i] = {
               post_id:id_arr[i],
               author:replies[i]['username'],
               name:convertEmailToName(replies[i]['email']),
               email:replies[i]['email'],
               university:replies[i]['university'],
               post_content:replies[i]['post_content'],
               course_code:replies[i]['course_code'],
               course_title:replies[i]['course_title'],
               professor:replies[i]['professor'],
               preferred_price:replies[i]['preferred_price'],
               front_cover:replies[i]['front_cover'],
               isbn_page:replies[i]['isbn_page'],
               book_condition:replies[i]['book_condition'],
               sold:replies[i]['sold'],
               timestamp_mil:replies[i]['timestamp_mil'],
               time:timeHelper(replies[i]['timestamp_mil']),
           }
       }
       //send the reply in json
       return res.json({success:true, postObject:json_send});
    });
};

String.prototype.capitalizeFirstLetter = function() {
    return this.charAt(0).toUpperCase() + this.slice(1);
}

var convertEmailToName = function(email){
    if (!email) return "";
    var firstItem = email.split('@');
    if (!firstItem||firstItem.length!=2) return "";
    var names = firstItem[0].split('.');
    var name = "";
    for (var i=0;i<names.length;i++){
        name+=names[i].capitalizeFirstLetter();
        if(i!=names.length-1)
        name+=" ";
    }
    return name;
}

//mark the post as sold
//Prerequisite: tokenMiddleware, ownershipCheck
posts.prototype.marksold = function(req, res, next){
    var postid = req.params.postid;
    client.HMSET('post:'+postid, 'sold', 'true', function(err, reply){
                 if(err){
                    debug(err);
                    return res.json({success:false, message:"mark sold failed, server error", code:"s01"});
                 }
         if(!reply) return res.json({success:false, message:"mark sold failed, no post found", code:"p17"});
         return res.json({success:true, postid:postid});
    });
};

//delete the post
//Prerequisite: tokenMiddleware, ownershipCheck
posts.prototype.deletePost = function(req, res, next){
    var postid = req.params.postid;
    client.hget('post:'+postid, 'university', function(err, reply){
        if(err){
            debug(err);
            return res.json({success:false, message:"delete post failed, server error", code:"s01"});
        };
        var university = reply;
        multi = client.multi();
        multi.DEL('post:'+postid);
        multi.DEL('buyPost:'+postid);
        multi.ZREM('university:'+university, postid);
        multi.ZREM('university:all', postid);
        multi.ZREM(req.decoded.username+":posts", postid);
        multi.SREM("userCollection:"+req.decoded.username, postid);
        multi.exec(function(err, replies){
            if(err) {
                debug(err);
                return res.json({success:false, message:"delete post failed, server error", code:"s01"});
            }
            return res.json({success:true});
        });
    });
    //also delete the post from the newsfeeds
    //the result of this operation is not replied to the user
    
};

//modify the post
//Prerequisite: tokenMiddleware, ownershipCheck, jsonParser
//to modify image url, just re-upload using the existing api
/* Only the part that needs modification is sent
 * {
 *   post_content:String, //optional, < 120 chars
 *   course_code:String,  //mandatory < 20 chars
 *   course_title:String, //mandatory < 60 chars
 *   professor: String,   //optional  < 60 chars
 *   book_condition: String, //mandatory
 * }
 */
posts.prototype.modifyPost = function(req, res, next){
    var postid = req.params.postid;
    var tmp = {};
    tmp.post_content = req.body.post_content;
    tmp.course_code = req.body.course_code;
    tmp.course_title = req.body.course_title;
    tmp.professor = req.body.professor;
    if(!tmp.post_content&&!tmp.course_code&&!tmp.course_title&&!tmp.professor)
        return res.json({success:false, message:"must modify at least on argument", code:"p18"});
    switch(req.body.book_condition){
        case 'brand_new':
            tmp.book_condition = 'brand_new';
            break;
            //book used but condition still good
        case 'used_good':
            tmp.book_condition = 'used_good';
            break;
            //book used with some damage
        case 'used_damage':
            tmp.book_condition = 'used_damage';
            break;
        default:
            return res.json({success:false, message:'book condition code wrong', code:'p15'})
    }
    //check the length of the post content
    if(charL(tmp.post_content)>120 || charL(tmp.course_code)>20 || charL(tmp.course_title)>60 || charL(tmp.professor)>60)
        return res.json({success:false, message:"Max char count reached", code:"p02"});
    //initialize the arguments array to be sent to redis
    var args = [];
    args[0] = 'post:'+postid;
    //populate the array while skipping the void results
    for(var key in tmp){
        if(tmp[key]){
            args.push(key);
            args.push(tmp[key]);
        }
    }
    client.hmset(args, function(err, reply){
         if(err){
            debug(err);
            return res.json({success:false, message:"modify post failed, server error"});
         }
         if(!reply){
            return res.json({success:false, message:"modify post failed, post not found", code:"p17"});
         }
         return res.json({success:true, postid:postid});
    });
};

/*
 *  Notify that a user has intended to purchase a textbook
 *  Prerequisite: tokenmiddleware
 */
posts.prototype.notifyMiddleware = function(req, res, next){
    //the user that has intention to purchase
    var fromUser = req.decoded.username;
    var postid = req.params.postid;
    client.hmget("post:"+req.params.postid, 'username', 'course_code', 'course_title', 'professor',function(err, reply){
        if(err){
            return res.json({success:false, message:"notify failed, server error", code:"s01"});
        }
        if(!reply){
            return res.json({success:false, message:"notify failed, post not found", code:"p06"});
        }
        var uname = reply[0];
        //now get the author email from the database
        user.findOne({username:uname},function(err, result){
            if(err){
                return res.json({success:false, message:"server error", code:"s01"});
            }
            if(!result){
                return res.json({success:false, message:"target user not found", code:"n01"})
            }
            var toEmail = result.uniMail;
            req.unibook.notifyTarget = toEmail;
            user.findOne({username:fromUser},function(err, result_source){
                  if(err){
                    return res.json({success:false, message:"server error", code:"s01"});
                  }
                  if(!result_source){
                    return res.json({success:false, message:" source user not found", code:"n01"})
                  }
                  var fromEmail = result_source.uniMail;
                  req.unibook.notifySource = fromEmail;
                  req.unibook.sourceName = result_source.name;
                  req.unibook.course_code = reply[1];
                  req.unibook.course_title = reply[2];
                  req.unibook.professor = reply[3];
                  next();
            });

        });

    });
};

//notify email middleware
//prerequisite: tokenmiddleware, notifyMiddleware
posts.prototype.emailMiddeware=function(req, res, next){

    pmark.sendEmail({
        "From": "unibook@hereips.com",
        "To": req.unibook.notifyTarget,
        "Subject": req.unibook.sourceName+" has indicated interest in buying yout textbook!",
        "ReplyTo":req.unibook.notifySource,
        "TextBody": "Hello from Unibook! " +"\n"+
                     req.unibook.sourceName+ " has told us that he/she is interested in your textbook:"+"\n"+
                     "Course Code: "+req.unibook.course_code+"\n"+
                     "Course Title: "+req.unibook.course_title+"\n"+
                     ((req.unibook.professor)?req.unibook.professor:"")+"\n"+
                     "You can reply directly to this email to chat with "+req.unibook.sourceName + "\n",
        },function(error, success){
            if(error){
                debug(error);
                return res.json({success:false, message:'cannot send email for verification to '+req.unibook.notifyTarget, code:'e01'});
            }
            debug('email sent to '+req.unibook.notifyTarget);
            next();
        });
     

};

//method to add the item to the seller and buyer's list
//prerequisite: tokenmiddleware, notifyMiddleware, emailMiddeware
posts.prototype.collectionMiddleware=function(req, res, next){
    var multi = client.multi();
    //the list of users after a book
    multi.sadd("buyPost:"+req.params.postid, req.decoded.username);
    //the books starred by a user
    multi.sadd("userCollection:"+req.decoded.username, req.params.postid);
    multi.exec(function(err, reply){
        if(err) debug(err);
        res.json({success:true});
    });
};

//middleware to get the list of interested buyers
//prerequisite: tokenmiddleware, ownershipCheck
posts.prototype.interestedMiddleware=function(req, res, next){
    client.SMEMBERS("buyPost:"+req.params.postid,function(err, reply){
        if(err){
            return res.json({success:false, message:"get interested post failed, server error", code:"s01"});
        }
        if(!reply){
            return res.json({success:true, list:0});
        }
        var multi = client.multi();
        for(var i=0;i<reply.length;i++){
            multi.hmget(req.decoded.username+":token","name", "email")
        }
        multi.exec(function(err, reply){
           if(err) return res.json({success:false, message:"get interested post failed, server error", code:"s01"});
           if(!reply) res.json({success:true, list:0});
           var json_send = [{}];
           for(var i=0;i<reply.length;i++){
            json_send[i].name = reply[i][0];
            json_send[i].email = reply[i][1];
           }
           return res.json({success:true, list:json_send});//[] of objects
        });
    });
};

//middleware to get the list of posts
//prerequisite: tokenmiddleware
//uses postMultiHelper, need to construct a req.unibook.unibookJsonRaw object with the keys as the post id
posts.prototype.getMyCollections=function(req, res, next){
    client.SMEMBERS("userCollection:"+req.decoded.username, function(err, reply){
        if(err){
            return res.json({success:false, message:"get collection post failed, server error", code:"s01"});
        }
        if(!reply){
            return res.json({success:true, postObject:0});
        }
        var obj_send = {};
        for(var i=0;i<reply.length;i++){
            obj_send[reply[i]] = {};
        }
        req.unibook.unibookJsonRaw = obj_send;
        next();
    });
};

//prerequisite:getMyCollections
posts.prototype.collectionId = function(req, res, next){
    if(req.unibook.unibookJsonRaw){
        var json_to_send = [];
        for (var key in req.unibook.unibookJsonRaw){
            json_to_send.push(key);
        }
        return res.json({success:true, postObject:json_to_send});
    }else {
        return res.json({success:false, message:"json empty"});
    }
}