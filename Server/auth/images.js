
/*
 * Class that handles files upload and file type verification
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
 *    s01 => Server: server error
 *    i01 => Server: server error
 *    i02 => Registration: user exists
 *    i03 => Send Image: User does not exist
 *    f01 => No profile image found on server
 */

var multer  = require('multer');//multer module is for file uploads
var Magic = require('mmmagic').Magic;//check the magic number of the image, only JPEG is acceptable
var config = require('../config');
var mongoose = require('mongoose');
var path = require('path');
//mongoose model for user
var user = require('../user/user.js');
var debug = require('debug')('images');
var fs = require('fs');

//configure multer image upload
var storage = multer.memoryStorage();

//connect mongoose to database
if(!mongoose.connection.readyState)
mongoose.connect(config.database, config.mongodb_opt);

//new magic object
var magic = new Magic();

module.exports = images = function() {

};

//multer middleware for limiting file size
images.prototype.multer_profile_upload = multer({ storage: storage , limits: {fileSize: config.MAX_FILE_SIZE_FOR_PROFILE_IMAGE_UPLOAD},
}).single('userfile');


//middleware for checking uploaded file type
//Prerequisites: tokenMiddleware, multer_profile_upload
images.prototype.profileTypeCheck = function (req, res, next){
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
                 fs.writeFile(path.join(__dirname, "/../files/profile_images/"+req.decoded.username+"_profile.jpg"), req.file.buffer, function(err) {
                              if(err) {console.log(err);
                                debug(err);
                                return res.status(403).json({ success: false, message: 'Upload failed. Server error.', code: 's01' });
                              }
                              //move on
                              next();
                 });
                 }
                 else {
                    debug(ip+' is sending wrong file type');
                    return res.status(403).json({success:false, message:'file type wrong', code:'i02'});;
                 }
                 });
};

//log the image url to database
//Prerequisites: tokenMiddleware, multer_profile_upload, profileTypeCheck
images.prototype.logProfileToDB = function (req, res, next){
    user.findOne({username:req.decoded.username},function(err, result){
                 if (err) {
                    debug(err);
                    return res.status(403).json({ success: false, message: 'Log profile url failed. Server error.' , code: 's01' });
                 };
                 //given username is not found on the database
                 if(!result){
                    debug('username'+uname+'not found');
                    return res.status(403).json({ success: false, message: 'Log profile url failed. User not found.', code: 'a01' });
                 } else if (result){
                     var timestamp = new Date().getTime();
                     result.profileURL = config.site_url+'/profile_img/'+req.decoded.username;
                     result.profileTimestamp = timestamp;
                     result.save(function(err){
                               if(err){
                                return res.status(403).json ({ success: false, message: 'Log profile url failed. Server error.' , code:'s01'});
                               }
                               req.unibook.profileImgUrl = result.profileURL;
                               next();
                     });
                 }
                 
    });
};

//prerequisite: tokenmiddleware
images.prototype.getProfileImgTimestamp = function(req, res, next){
    var uname = req.decoded.username;
    user.findOne({username:uname},function(err, result){
                 if (err) {
                    debug(err);
                    return res.status(403).json({ success: false, message: 'Get profile image timestamp failed. Server error.' , code: 's01' });
                 };
                 //given username is not found on the database
                 if(!result){
                    debug('username'+uname+'not found');
                    return res.status(403).json({ success: false, message: 'Get profile image timestamp failed. User not found.', code: 'a01' });
                 } else if (result){
                    var timestamp = result.profileTimestamp;
                 return res.json({success:true, timestamp:timestamp});
                 }
                 
    });
};

//middleware to send profile image to client
//if success, the content-type will be: Content-Type: image/jpeg
//if failed, the content-type will be: Content-Type: application/json; charset=utf-8
images.prototype.sendProflieImage = function (req, res, next, value){
    var uname = req.body.username;
    user.findOne({username:uname},function(err, result){
                 if(err){
                    debug(err);
                    return res.status(403).json({success: false, message: 'send profile img failed. Server error.' , code:'s01'});
                 }
                 if (!result){
                    return res.status(403).json({success: false, message: 'send profile img failed. Server error.' , code:'s01'});
                 }
    });
    res.sendFile(uname+'_profile.jpg', { root: path.join(__dirname, '../files/profile_images/') }, function(err){
        if(err)
                 return res.json({success: false, message: 'No Profile Image' , code:'f01'});
    });
};