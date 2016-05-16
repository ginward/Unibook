
/*
 * the class to search textbooks
 * currently we are only indexing course codes
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
 * Error table:
 * se01: no post found
 */

var redis = require('redis');
var config = require('../config');
var university = require('../university.js');
var debug = require('debug')('search');
//create redis client
var client = redis.createClient();

client.on("error", function (err) {
          debug("Error " + err);
});


module.exports = search = function(){

}

//index the post, sorted set with score as 0
//sortedset format 0 CourseCode:Postid:Timestemp
//prerequsite: getUserUniMiddleware, newPost
search.prototype.indexPostMiddleware = function(req, res, next){
    var universityName = req.unibook.UserUniname;
    var course_code_raw = req.body.course_code;
    var course_code = course_code_raw.toLowerCase();//index with the lowercase letter
    var post_id = req.body.post_id;
    var timestamp = req.unibook.uniNewpostTime;
    client.zadd("universityIndex:"+universityName, '0', course_code+":"+timestamp+":"+post_id, function(err, reply){
        if(err) debug(err);
        next();
    });
};

//delete the index of the post, so the book will no longer appear in the search results
//prerequsite: ownershipcheck
search.prototype.deleteIndexPost = function(req, res, next){
    var postid = req.params.postid;
    client.hmget("post:"+postid, "course_code", "university", "timestamp",function(err, reply){
                 if(err) {
                    debug(err);
                    next();
                 }
                 if(!reply){
                    next();
                 }
                 var course_code = reply[0];
                 var university = reply[1];
                 var timestamp = reply[2];
                 client.ZREM("universityIndex:"+university, course_code+":"+timestamp+":"+postid, function(err, reply){
                                       if(err) debug(err);
                                       next();
                 });
    });
};

//middleware to search post via course code
//prerequisite: jsonParser
search.prototype.searchPostMiddleware = function(req, res, next){
    var course_code_raw = req.body.course_code;
    var course_code = course_code_raw.toLowerCase();//index with the lowercase letter
    var uniDomain = req.body.uniDomain;
    var universityName = university[uniDomain];
    var lastTimestamp = req.body.lastTimestamp; //if lastTimestamp, it is the (refresh) first search
    var offset = req.body.offset;
    //the returned result should be sorted by lex and timestamp
    client.ZREVRANGEBYLEX("universityIndex:"+universityName, "["+course_code+(lastTimestamp==0?"" : ":"+lastTimestamp)+":\xff", "["+course_code+":", "LIMIT", offset, config.SEARCH_RESULT_PAGINATION, function(err, reply){
          if(err){
            debug(err);
            return res.json({success:false, message:"search via course code failed, server error", code:"s01"});
          }
          if(!reply)
            return res.json({success:false, message:"no post found", code:"se01"});
          //construct an object with keys as postids and pass it to postmultihelper
          var json_raw = {};
          for(var i=0;i<reply.length;i++){
            if(reply[i]){
                var tmp_arr = reply[i].split(':');
                json_raw[tmp_arr[tmp_arr.length-1]] = {};
            }
          }
          req.unibook.unibookJsonRaw = json_raw;
          next();
    });
};
