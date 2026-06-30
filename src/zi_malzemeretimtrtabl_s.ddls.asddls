@EndUserText.label: 'Malzeme Üretim Türü Tabl. Singleton'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.semanticKey: [ 'SingletonID' ]
@UI: {
  headerInfo: {
    typeName: 'MalzemeRetimTRTaAll'
  }
}
define root view entity ZI_MalzemeRetimTRTabl_S
  as select from I_Language
    left outer join I_CstmBizConfignLastChgd on I_CstmBizConfignLastChgd.ViewEntityName = 'ZI_MALZEMERETIMTRTABL'
  composition [0..*] of ZI_MalzemeRetimTRTabl as _MalzemeRetimTRTabl
{
  @UI.facet: [ {
    id: 'ZI_MalzemeRetimTRTabl', 
    purpose: #STANDARD, 
    type: #LINEITEM_REFERENCE, 
    label: 'Malzeme Üretim Türü Tabl.', 
    position: 1 , 
    targetElement: '_MalzemeRetimTRTabl'
  } ]
  @UI.lineItem: [ {
    position: 1 
  } ]
  key 1 as SingletonID,
  _MalzemeRetimTRTabl,
  @UI.hidden: true
  I_CstmBizConfignLastChgd.LastChangedDateTime as LastChangedAtMax
}
where I_Language.Language = $session.system_language
