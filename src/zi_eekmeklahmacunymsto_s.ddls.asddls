@EndUserText.label: ' E.Ekmek-Lahmacun YM Stok Tabl. Singleto'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.semanticKey: [ 'SingletonID' ]
@UI: {
  headerInfo: {
    typeName: 'EEkmekLahmacunYmAll'
  }
}
define root view entity ZI_EEkmekLahmacunYmSto_S
  as select from I_Language
    left outer join I_CstmBizConfignLastChgd on I_CstmBizConfignLastChgd.ViewEntityName = 'ZI_EEKMEKLAHMACUNYMSTO'
  composition [0..*] of ZI_EEkmekLahmacunYmSto as _EEkmekLahmacunYmSto
{
  @UI.facet: [ {
    id: 'ZI_EEkmekLahmacunYmSto', 
    purpose: #STANDARD, 
    type: #LINEITEM_REFERENCE, 
    label: ' E.Ekmek-Lahmacun YM Stok Tabl.', 
    position: 1 , 
    targetElement: '_EEkmekLahmacunYmSto'
  } ]
  @UI.lineItem: [ {
    position: 1 
  } ]
  key 1 as SingletonID,
  _EEkmekLahmacunYmSto,
  @UI.hidden: true
  I_CstmBizConfignLastChgd.LastChangedDateTime as LastChangedAtMax
}
where I_Language.Language = $session.system_language
