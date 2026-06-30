@EndUserText.label: 'Vardiya No Tabl. Singleton'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.semanticKey: [ 'SingletonID' ]
@UI: {
  headerInfo: {
    typeName: 'VardiyaNoTablAll'
  }
}
define root view entity ZI_VardiyaNoTabl_S
  as select from I_Language
    left outer join I_CstmBizConfignLastChgd on I_CstmBizConfignLastChgd.ViewEntityName = 'ZI_VARDIYANOTABL'
  composition [0..*] of ZI_VardiyaNoTabl as _VardiyaNoTabl
{
  @UI.facet: [ {
    id: 'ZI_VardiyaNoTabl', 
    purpose: #STANDARD, 
    type: #LINEITEM_REFERENCE, 
    label: 'Vardiya No Tabl.', 
    position: 1 , 
    targetElement: '_VardiyaNoTabl'
  } ]
  @UI.lineItem: [ {
    position: 1 
  } ]
  key 1 as SingletonID,
  _VardiyaNoTabl,
  @UI.hidden: true
  I_CstmBizConfignLastChgd.LastChangedDateTime as LastChangedAtMax
}
where I_Language.Language = $session.system_language
