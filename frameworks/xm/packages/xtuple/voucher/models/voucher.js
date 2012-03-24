// ==========================================================================
// Project:   xTuple Postbooks - Business Management System Framework        
// Copyright: ©2012 OpenMFG LLC, d/b/a xTuple                             
// ==========================================================================

/*globals XM */

sc_require('packages/xtuple/voucher/mixins/_voucher');

/**
  @class

  @extends XM.Document
*/
XM.Voucher = XM.Document.extend(XM._Voucher,
  /** @scope XM.Voucher.prototype */ {

  numberPolicy: XM.AUTO_NUMBER,
  
  // .................................................
  // CALCULATED PROPERTIES
  //

  //..................................................
  // METHODS
  //

  //..................................................
  // OBSERVERS
  //

});

