
/*
 * List of Universities email address
 * Only university students are able to register
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

//cron job to fetch university list every hour
var cron = require('cron');
var redis = require('redis');
var debug = require('debug')('universityList');

var uniclient = redis.createClient();
uniclient.on("error", function (err) {
          debug("Error " + err);
          throw(err);
});

module.exports = uniObj = {
    "harvard.edu":"Harvard University",
    "utoronto.ca":"University of Toronto",
    "stanford.edu":"Stanford University",
}

//this cron job operates every hour
var cronJob = cron.job("0 0 * * * *", function(){
                       // perform operation e.g. GET request http.get() etc.
                       updateList();
                       debug("updating list");
});
cronJob.start();

//synv the university list
var updateList = function(){
    uniclient.hgetall('uniList',function(err, reply){
                  if(err){
                    debug(err);
                    return;
                  }
                  Object.keys(uniObj).forEach(function(k){
                      if((reply)&&(reply[k])&&uniObj[k]!=reply[k]){
                        uniObj[k]!=reply[k];
                      }
                      if((reply)&&!(k in reply)){
                        //we don't delete those three schools from the list
                        if(k!="harvard.edu"&&k!="utoronto.ca"&&k!="stanford.edu"){
                            delete uniObj[k];
                        }
                      }
                  });
                  debug("list updated");
    });
}