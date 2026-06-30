@EndUserText.label: 'Mamul Kurabiye Araba KG. Tabl. Singleton'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.semanticKey: [ 'SingletonID' ]
@UI: {
  headerInfo: {
    typeName: 'MamulKurabiyeAraAll'
  }
}
define root view entity ZI_MamulKurabiyeArabaK_S
  as select from I_Language
    left outer join I_CstmBizConfignLastChgd on I_CstmBizConfignLastChgd.ViewEntityName = 'ZI_MAMULKURABIYEARABAK'
  composition [0..*] of ZI_MamulKurabiyeArabaK as _MamulKurabiyeArabaK
{
  @UI.facet: [ {
    id: 'ZI_MamulKurabiyeArabaK', 
    purpose: #STANDARD, 
    type: #LINEITEM_REFERENCE, 
    label: 'Mamul Kurabiye Araba KG. Tabl.', 
    position: 1 , 
    targetElement: '_MamulKurabiyeArabaK'
  } ]
  @UI.lineItem: [ {
    position: 1 
  } ]
  key 1 as SingletonID,
  _MamulKurabiyeArabaK,
  @UI.hidden: true
  I_CstmBizConfignLastChgd.LastChangedDateTime as LastChangedAtMax
}
where I_Language.Language = $session.system_language
