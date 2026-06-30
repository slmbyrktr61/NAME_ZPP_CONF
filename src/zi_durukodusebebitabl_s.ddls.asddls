@EndUserText.label: 'Duruş Kodu-Sebebi Tabl. Singleton'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.semanticKey: [ 'SingletonID' ]
@UI: {
  headerInfo: {
    typeName: 'DuruKoduSebebiTaAll'
  }
}
define root view entity ZI_DuruKoduSebebiTabl_S
  as select from I_Language
    left outer join I_CstmBizConfignLastChgd on I_CstmBizConfignLastChgd.ViewEntityName = 'ZI_DURUKODUSEBEBITABL'
  composition [0..*] of ZI_DuruKoduSebebiTabl as _DuruKoduSebebiTabl
{
  @UI.facet: [ {
    id: 'ZI_DuruKoduSebebiTabl', 
    purpose: #STANDARD, 
    type: #LINEITEM_REFERENCE, 
    label: 'Duruş Kodu-Sebebi Tabl.', 
    position: 1 , 
    targetElement: '_DuruKoduSebebiTabl'
  } ]
  @UI.lineItem: [ {
    position: 1 
  } ]
  key 1 as SingletonID,
  _DuruKoduSebebiTabl,
  @UI.hidden: true
  I_CstmBizConfignLastChgd.LastChangedDateTime as LastChangedAtMax
}
where I_Language.Language = $session.system_language
