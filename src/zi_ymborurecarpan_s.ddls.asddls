@EndUserText.label: 'YM Börek Üretiminde Çarpan Sayı Singleto'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.semanticKey: [ 'SingletonID' ]
@UI: {
  headerInfo: {
    typeName: 'YmBorUreCarpanAAll'
  }
}
define root view entity ZI_YmBorUreCarpan_S
  as select from I_Language
    left outer join I_CstmBizConfignLastChgd on I_CstmBizConfignLastChgd.ViewEntityName = 'ZI_YMBORURECARPAN'
  composition [0..*] of ZI_YmBorUreCarpan as _YmBorUreCarpan
{
  @UI.facet: [ {
    id: 'ZI_YmBorUreCarpan', 
    purpose: #STANDARD, 
    type: #LINEITEM_REFERENCE, 
    label: 'YM Börek Üretiminde Çarpan Sayı', 
    position: 1 , 
    targetElement: '_YmBorUreCarpan'
  } ]
  @UI.lineItem: [ {
    position: 1 
  } ]
  key 1 as SingletonID,
  _YmBorUreCarpan,
  @UI.hidden: true
  I_CstmBizConfignLastChgd.LastChangedDateTime as LastChangedAtMax
}
where I_Language.Language = $session.system_language
