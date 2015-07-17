var _      = require('underscore'),
    assert = require('chai').assert,
    path   = require('path');

(function () {
  'use string';
  describe('createpkgschema()', function () {

    var loginData  = require('../../lib/login_data.js').data,
        datasource = require('../../../node-datasource/lib/ext/datasource').dataSource,
        config     = require('../../../node-datasource/config.js'),
        creds      = _.extend({}, config.databaseServer,
                              { database: loginData.org }),
        firstOid   = -1;

    it('should create a schema', function (done) {
      var sql = "select createpkgschema('test', 'test comment') as soid;";
      datasource.query(sql, creds, function (err, res) {
        assert.isNull(err);
        firstOid = res.rows[0].soid;
        assert.isTrue(firstOid >= 0);
        done();
      });
    });

    it('should have created several tables', function (done) {
      var sql = "select relname"                                        +
                "  from pg_class c"                                     +
                "  join pg_namespace n on c.relnamespace = n.oid"       +
                " where nspname = 'test';";
      datasource.query(sql, creds, function (err, res) {
        assert.isNull(err);
        assert.isObject(_.find(res.rows, function (e) { return e.relname == 'pkgcmd';     }), "expected 'pkgcmd'");
        assert.isObject(_.find(res.rows, function (e) { return e.relname == 'pkgcmdarg';  }), "expected 'pkgcmdarg'");
        assert.isObject(_.find(res.rows, function (e) { return e.relname == 'pkgimage';   }), "expected 'pkgimage'");
        assert.isObject(_.find(res.rows, function (e) { return e.relname == 'pkgmetasql'; }), "expected 'pkgmetasql'");
        assert.isObject(_.find(res.rows, function (e) { return e.relname == 'pkgpriv';    }), "expected 'pkgpriv'");
        assert.isObject(_.find(res.rows, function (e) { return e.relname == 'pkgreport';  }), "expected 'pkgreport'");
        assert.isObject(_.find(res.rows, function (e) { return e.relname == 'pkgscript';  }), "expected 'pkgscript'");
        assert.isObject(_.find(res.rows, function (e) { return e.relname == 'pkguiform';  }), "expected 'pkguiform'");
        done();
      });
    });

    it('should be idempotent', function (done) {
      var sql = "select createpkgschema('test', 'test comment') as soid;";
      datasource.query(sql, creds, function (err, res) {
        assert.isNull(err);
        assert.equal(firstOid, res.rows[0].soid);
        assert.isTrue(firstOid >= 0);
        done();
      });
    });

    after(function (done) {
      var sql = "select deletepackage(pkghead_id) from pkghead" +
                " where pkghead_name = 'test';";
      datasource.query(sql, creds, done);
    });
  });
})();
