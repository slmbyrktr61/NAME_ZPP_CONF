@EndUserText.label: 'Grup Tablosu Singleton'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.semanticKey: [ 'SingletonID' ]
@UI: {
  headerInfo: {
    typeName: 'GrupTablosuAll'
  }
}
define root view entity ZI_GrupTablosu_S
  as select from I_Language
    left outer join I_CstmBizConfignLastChgd on I_CstmBizConfignLastChgd.ViewEntityName = 'ZI_GRUPTABLOSU'
  composition [0..*] of ZI_GrupTablosu as _GrupTablosu
{
  @UI.facet: [ {
    id: 'ZI_GrupTablosu', 
    purpose: #STANDARD, 
    type: #LINEITEM_REFERENCE, 
    label: 'Grup Tablosu', 
    position: 1 , 
    targetElement: '_GrupTablosu'
  } ]
  @UI.lineItem: [ {
    position: 1 
  } ]
  key 1 as SingletonID,
  _GrupTablosu,
  @UI.hidden: true
  I_CstmBizConfignLastChgd.LastChangedDateTime as LastChangedAtMax
}
where I_Language.Language = $session.system_language
