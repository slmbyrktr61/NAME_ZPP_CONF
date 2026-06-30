@EndUserText.label: 'Kepek Malzeme Tabl. Singleton'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.semanticKey: [ 'SingletonID' ]
@UI: {
  headerInfo: {
    typeName: 'KepekMalzemeTablAll'
  }
}
define root view entity ZI_KepekMalzemeTabl_S12
  as select from I_Language
    left outer join I_CstmBizConfignLastChgd on I_CstmBizConfignLastChgd.ViewEntityName = 'ZI_KEPEKMALZEMETABL'
  composition [0..*] of ZI_KepekMalzemeTabl as _KepekMalzemeTabl
{
  @UI.facet: [ {
    id: 'ZI_KepekMalzemeTabl', 
    purpose: #STANDARD, 
    type: #LINEITEM_REFERENCE, 
    label: 'Kepek Malzeme Tabl.', 
    position: 1 , 
    targetElement: '_KepekMalzemeTabl'
  } ]
  @UI.lineItem: [ {
    position: 1 
  } ]
  key 1 as SingletonID,
  _KepekMalzemeTabl,
  @UI.hidden: true
  I_CstmBizConfignLastChgd.LastChangedDateTime as LastChangedAtMax
}
where I_Language.Language = $session.system_language
