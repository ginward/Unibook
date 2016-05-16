
/*
 * The main entry point for unibook server
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

process.env.NODE_ENV = 'production';//set the production mode to supress errors from the user
var express = require('express');
var auth = require('./auth/auth.js');
var images = require('./auth/images.js');
var search = require('./posts/search.js')
var posts = require('./posts/posts.js');
var bodyParser = require('body-parser');
var config = require('./config.js');
var http = require('http');
var https = require('https');
var fs = require('fs');
var filter = require('content-filter');//filter $ and {
//var privateKey  = fs.readFileSync('sslcert/server.key', 'utf8');
//var certificate = fs.readFileSync('sslcert/server.crt', 'utf8');
//credential for https
//var credentials = {key: privateKey, cert: certificate};

var urlParser = bodyParser.urlencoded({ extended: false });

var jsonParser = bodyParser.json();

//construct the authorization object
var authObj = new auth();

//construct the image object
var imgObj = new images();

//construct the post object
var postObj = new posts();

//construct the search object
var searchObj = new search();

var uniRoutes = express.Router();

uniRoutes.use(jsonParser);

uniRoutes.use(urlParser);

uniRoutes.use(filter());

/* to register the user
 * request: {username:String, password:String, email:String, name:String}
 * username length must fall within [5, 10] characters, password length must fall within [5, 20] chracteres
 */
uniRoutes.post('/register', authObj.valididateUnamePwd, authObj.validateEmail, authObj.registerMiddleware, function(req, res){
    //response sent in the middleware
});

//check if the username is valid
//{username:String}
uniRoutes.post('/uniqueUsr', authObj.uniqueUsrMiddleware, function(req, res){
//response sent in the middleware
});

//check if the provided email is an official university email address in list
//{email:String}
uniRoutes.post('/officialEmail', authObj.validateEmail, function(req, res){
    res.json({success:true});
});

//request:{username:String, password:String}
uniRoutes.post('/login', authObj.authenticationMiddleware, authObj.getUserUniMiddleware, authObj.authResponseMiddleware, function(req, res){
    //response sent in the middleware
});

//request:{username:String, oldPWD:String, newPWD:String}
uniRoutes.post('/changePassword', authObj.changePWDMiddleware, function(req, res){
    //response sent in the middleware
});

//request:{username:username}
uniRoutes.post('/profile_img', imgObj.sendProflieImage, function(req, res){
    //nothing needs to be done here
});

//get the post images
uniRoutes.get('/post_img/:post_id/:img_type', postObj.sendPostImg, function(req, res){
    
});

//for app demo only, no personal information such as email address shall be leaked here
uniRoutes.get('/postFeedAll/', postObj.nonAuthPosts, postObj.nonAuthPostMultiHelper, function(req, res){
    //response sent in the middleware
});

//get the number of interested buyers - this does not requires login
uniRoutes.get('/interestCount/:postid', function(req, res){
   //results sent in the middleware
});

/*************** Authenticated Routes Start Here ****************/

uniRoutes.use(authObj.tokenMiddleware); //authenticate

//verify the user email with verification code
uniRoutes.get('/emailVerify/:veriCode', authObj.emailVerificationMiddleware, function(req, res){
              //respond sent in the middleware
});

uniRoutes.use(authObj.unibookShield); //block the unverified users

//a simple route to allow the client check if the current token is valid
uniRoutes.get('/validateToken', authObj.tokenMiddleware, function(req, res){
    res.json({success:true});
});

//change my name
//requset:{newName:String}
uniRoutes.post('/changename', authObj.changeNameMiddleware, function(req, res){
    //response sent in the middleware
});

//resend verification code via email
uniRoutes.get('/resendVeriMail', authObj.resendEmailMiddleware, function(req, res){
    //respond sent in the middleware
});

//route to upload the profile image (single image)
uniRoutes.post('/uploadProfileImage', imgObj.multer_profile_upload, imgObj.profileTypeCheck, imgObj.logProfileToDB, function(req, res){
              res.json({success:true,profileUrl:req.unibook.profileImgUrl});
});

//get the timestamp of the profile image
uniRoutes.get('/profileImgTimestamp', function(req, res){
    //response sent in the middleware
});

//upload decription of the post
uniRoutes.post('/newPost', authObj.getUserUniMiddleware, postObj.newPost, searchObj.indexPostMiddleware, postObj.postFeed, function(req, res){
               res.json({success:true, post_id:req.body.post_id});
});

//upload the images of the post, one at a time
uniRoutes.post('/newPostImgs/:postid:/:imgType', postObj.ownershipCheck, postObj.multer_profile_upload, postObj.imgTypeCheck, postObj.logFileToRedis, function(req, res){
                res.json({success:true,postImgUrl:req.unibook.postImgUrl});
});


//search the post with course code
//{course_code:String, uniDomain:String, lastTimestamp:String, offset:String}
uniRoutes.post('/search', searchObj.searchPostMiddleware, postObj.postMultiHelper, function(err, reply){
    //response sent in the middleware
});

//mark the post as sold
//must do ownership check
uniRoutes.post('/markSold/:postid', postObj.ownershipCheck, postObj.marksold ,function(req, res){
    //response sent in the middleware
});

//delete the spcified post
//must do ownership check
uniRoutes.get('/delete/:postid', postObj.ownershipCheck, searchObj.deleteIndexPost, postObj.deletePost,function(req, res){
    //response sent in the middleware
});

//get a specific post
//@return: post content in json of one post
uniRoutes.post('/getPost/:postid', postObj.getPost, function(req, res){
    //response already sent in the middleware getPost
});

//modify the content of a post
uniRoutes.post('/modifyPost/:postid', postObj.ownershipCheck, postObj.modifyPost, function(req, res){
    //response sent in the middleware
});

/* Get the historical post of a user */
uniRoutes.get('/historyPosts', postObj.getPostByUsername, postObj.postMultiHelper,function(req, res){
    //response sent in the middleware
});

//get the list of interested buyers
uniRoutes.get('/interestedBuyers/:postid', postObj.ownershipCheck, postObj.interestedMiddleware, function(req, res){
    //response sent in the middleware
});

//query the post feed of the university
//request{uniDomain:String, clientTimestamp:String, clientPostid:String, clientRepeatPost:String, direction:String}
//@param: uniDomain the domain of the university in query
uniRoutes.post('/postFeed', postObj.getPostsUni, postObj.postMultiHelper, function(req, res){
    //response sent in the middleware
});

//notify a user someone has intention to purchase a textbook
uniRoutes.get('/notify/:postid', postObj.notifyMiddleware, postObj.emailMiddeware, postObj.collectionMiddleware, function(req, res){
   //response sent in the middleware
});

//gets the post that I intended to buy
uniRoutes.get('/mycollection', postObj.getMyCollections, postObj.postMultiHelper, function(req, res){
    //response sent in the middleware
});

//gets the post that I intended to buy
uniRoutes.get('/mycollectionId', postObj.getMyCollections, postObj.collectionId, function(req, res){
        //response sent in the middleware
});

//server online here
var app = new express();
app.use(express.static(__dirname + '/web'));
app.use('/',uniRoutes);
var httpServer = http.createServer(app);
//var httpsServer = https.createServer(credentials, app);
httpServer.listen(process.env.PORT || 8080, '127.0.0.1', function(){
    console.log('Listening on port '+((process.env.PORT || 8080)));
});
//httpsServer.listen(443);
