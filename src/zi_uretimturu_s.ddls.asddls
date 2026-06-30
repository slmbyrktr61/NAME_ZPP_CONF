@EndUserText.label: 'Üretim Türü Tabl. Singleton'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.semanticKey: [ 'SingletonID' ]
@UI: {
  headerInfo: {
    typeName: 'UretimTuruTablAll'
  }
}
define root view entity ZI_UretimTuru_S
  as select from I_Language
    left outer join I_CstmBizConfignLastChgd on I_CstmBizConfignLastChgd.ViewEntityName = 'ZI_URETIMTURUTABL'
  composition [0..*] of ZI_UretimTuruTabl as _UretimTuruTabl
{
  @UI.facet: [ {
    id: 'ZI_UretimTuruTabl', 
    purpose: #STANDARD, 
    type: #LINEITEM_REFERENCE, 
    label: 'Üretim Türü Tabl.', 
    position: 1 , 
    targetElement: '_UretimTuruTabl'
  } ]
  @UI.lineItem: [ {
    position: 1 
  } ]
  key 1 as SingletonID,
  _UretimTuruTabl,
  @UI.hidden: true
  I_CstmBizConfignLastChgd.LastChangedDateTime as LastChangedAtMax
}
where I_Language.Language = $session.system_language
