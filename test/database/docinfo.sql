/*jshint trailing:true, white:true, indent:2, strict:true, curly:true,
  immed:true, eqeqeq:true, forin:true, latedef:true,
  newcap:true, noarg:true, undef:true */
/*global XT:true, describe:true, it:true, require:true, __dirname:true, after:true */

var _ = require("underscore"),
  assert = require('chai').assert,
  datasource = require('../../node-datasource/lib/ext/datasource').dataSource,
  path = require('path');

(function () {
  "use strict";
  describe('Document Associations', function () {
    var loginData = require(path.join(__dirname, "../lib/login_data.js")).data,
      datasource = require('../../node-datasource/lib/ext/datasource').dataSource,
      config = require(path.join(__dirname, "../../node-datasource/config.js")),
      creds = config.databaseServer,
      databaseName = loginData.org;

    it('should succeed calling login() to set search_path', function (done) {
      var sql = "select login() as result;";
      creds.database = databaseName;
      datasource.query(sql, creds, function (err, res) {
        assert.isNull(err);
        var result = res.rows[0].result;
        assert(res.rows[0].result >= 0, 'login() returned without error');
        done();
      });
    });

    it('should have a reasonable search_path', function (done) {
      var sql = "select show_search_path() as result;";
      creds.database = databaseName;
      datasource.query(sql, creds, function (err, res) {
        assert.isNull(err);
        var path = res.rows[0].result;
        console.log(path);
        assert.match(path, /xt/,         'search path includes xt');
        assert.match(path, /public/,     'search path includes public');
        assert.match(path, /api/,        'search path includes api');
        assert.match(path, /fixcountry/, 'search path includes fixcountry');
        done();
      });
    });

    it('should be retrievable from the function', function (done) {
      var sql = "select * from _docinfo();";
      creds.database = databaseName;
      datasource.query(sql, creds, function (err, res) {
        assert.isNull(err);
        done();
      });
    });

    it('should be retrievable from the view', function (done) {
      var sql = "select * from docinfo;";
      creds.database = databaseName;
      datasource.query(sql, creds, function (err, res) {
        assert.isNull(err);
        done();
      });
    });

  });
}());
