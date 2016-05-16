
/*
 * The configuration file for unibook server.
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

//db.createUser({user: "sunpotter", pwd: "Harvard2013", roles: [ { role: "readWrite", db: "unibook"}]})
module.exports = {
    database:'mongodb://localhost:27017/unibook',
    mongodb_opt:{
        server: { poolSize: 5 },
        user: '',
        pass: '',
        auth: {
               authdb: 'admin'
        },
    },
    jwtsecret:'',
    MAX_FILE_SIZE_FOR_PROFILE_IMAGE_UPLOAD:1048576, //1MB
    MAX_FILE_SIZE_FOR_BOOK_IMAGE_UPLOAD:5242880, //5MB
    site_url:'',
    http_site_url:'',
    MAX_POST_PER_UNIVERSITY: 1000000, //maximum number of posts we keep per university
    MAX_POST_ALL:1000000, //maximum number of posts we keep for all universities
    PAGINATION:10,//20 posts to download per page
    POST_MARK_TOKEN:'',
    SEARCH_RESULT_PAGINATION:10,
}