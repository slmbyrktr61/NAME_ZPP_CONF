@EndUserText.label: 'Üretim Türü Tabl. Singleton'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.semanticKey: [ 'SingletonID' ]
@UI: {
  headerInfo: {
    typeName: 'RetimTRTablAll'
  }
}
define root view entity ZI_RetimTRTablS13
  as select from I_Language
    left outer join I_CstmBizConfignLastChgd on I_CstmBizConfignLastChgd.ViewEntityName = 'ZI_RETIMTRTABL'
  composition [0..*] of ZI_RetimTRTabl as _RetimTRTabl
{
  @UI.facet: [ {
    id: 'ZI_RetimTRTabl', 
    purpose: #STANDARD, 
    type: #LINEITEM_REFERENCE, 
    label: 'Üretim Türü Tabl.', 
    position: 1 , 
    targetElement: '_RetimTRTabl'
  } ]
  @UI.lineItem: [ {
    position: 1 
  } ]
  key 1 as SingletonID,
  _RetimTRTabl,
  @UI.hidden: true
  I_CstmBizConfignLastChgd.LastChangedDateTime as LastChangedAtMax
}
where I_Language.Language = $session.system_language
