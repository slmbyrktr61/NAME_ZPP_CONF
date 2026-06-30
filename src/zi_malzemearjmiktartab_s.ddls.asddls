@EndUserText.label: 'Malzeme Şarj Miktarı Tabl. Singleton'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.semanticKey: [ 'SingletonID' ]
@UI: {
  headerInfo: {
    typeName: 'MalzemeArjMiktarAll'
  }
}
define root view entity ZI_MalzemeArjMiktarTab_S
  as select from I_Language
    left outer join I_CstmBizConfignLastChgd on I_CstmBizConfignLastChgd.ViewEntityName = 'ZI_MALZEMEARJMIKTARTAB'
  composition [0..*] of ZI_MalzemeArjMiktarTab as _MalzemeArjMiktarTab
{
  @UI.facet: [ {
    id: 'ZI_MalzemeArjMiktarTab', 
    purpose: #STANDARD, 
    type: #LINEITEM_REFERENCE, 
    label: 'Malzeme Şarj Miktarı Tabl.', 
    position: 1 , 
    targetElement: '_MalzemeArjMiktarTab'
  } ]
  @UI.lineItem: [ {
    position: 1 
  } ]
  key 1 as SingletonID,
  _MalzemeArjMiktarTab,
  @UI.hidden: true
  I_CstmBizConfignLastChgd.LastChangedDateTime as LastChangedAtMax
}
where I_Language.Language = $session.system_language
