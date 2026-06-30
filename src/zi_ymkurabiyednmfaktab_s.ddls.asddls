@EndUserText.label: 'YM Dönüşüm Fak.Tabl. Singleton'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.semanticKey: [ 'SingletonID' ]
@UI: {
  headerInfo: {
    typeName: 'YmKurabiyeDNMFakAll'
  }
}
define root view entity ZI_YmKurabiyeDNMFakTab_S
  as select from I_Language
    left outer join I_CstmBizConfignLastChgd on I_CstmBizConfignLastChgd.ViewEntityName = 'ZI_YMKURABIYEDNMFAKTAB'
  composition [0..*] of ZI_YmKurabiyeDNMFakTab as _YmKurabiyeDNMFakTab
{
  @UI.facet: [ {
    id: 'ZI_YmKurabiyeDNMFakTab', 
    purpose: #STANDARD, 
    type: #LINEITEM_REFERENCE, 
    label: 'YM Dönüşüm Fak.Tabl.', 
    position: 1 , 
    targetElement: '_YmKurabiyeDNMFakTab'
  } ]
  @UI.lineItem: [ {
    position: 1 
  } ]
  key 1 as SingletonID,
  _YmKurabiyeDNMFakTab,
  @UI.hidden: true
  I_CstmBizConfignLastChgd.LastChangedDateTime as LastChangedAtMax
}
where I_Language.Language = $session.system_language
