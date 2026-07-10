@EndUserText.label: 'Mamul Dışı Yemek Duruş Malz. Tabl. Singl'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.semanticKey: [ 'SingletonID' ]
@UI: {
  headerInfo: {
    typeName: 'MamulDYemekDuruMAll'
  }
}
define root view entity ZI_MAMULDISIYEMEKDURUS
  as select from I_Language
    left outer join I_CstmBizConfignLastChgd on I_CstmBizConfignLastChgd.ViewEntityName = 'ZI_MAMULDISIYEMEKDURUS15'
  composition [0..*] of ZI_MamulDisiYemekDurus15 as _MamulDisiYemekDurus
{
  @UI.facet: [ {
    id: 'ZI_MamulDisiYemekDurus15', 
    purpose: #STANDARD, 
    type: #LINEITEM_REFERENCE, 
    label: 'Mamul Dışı Yemek Duruş Malz. Tabl.', 
    position: 1 , 
    targetElement: '_MamulDisiYemekDurus'
  } ]
  @UI.lineItem: [ {
    position: 1 
  } ]
  key 1 as SingletonID,
  _MamulDisiYemekDurus,
  @UI.hidden: true
  I_CstmBizConfignLastChgd.LastChangedDateTime as LastChangedAtMax
}
where I_Language.Language = $session.system_language
