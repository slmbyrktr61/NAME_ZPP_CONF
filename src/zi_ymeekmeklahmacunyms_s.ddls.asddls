@EndUserText.label: 'YM E.Ekmek-Lahmacun YM Stok Tabl. Single'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.semanticKey: [ 'SingletonID' ]
@UI: {
  headerInfo: {
    typeName: 'YmEEkmekLahmacunAll'
  }
}
define root view entity ZI_YmEEkmekLahmacunYmS_S
  as select from I_Language
    left outer join I_CstmBizConfignLastChgd on I_CstmBizConfignLastChgd.ViewEntityName = 'ZI_YMEEKMEKLAHMACUNYMS'
  composition [0..*] of ZI_YmEEkmekLahmacunYmS as _YmEEkmekLahmacunYmS
{
  @UI.facet: [ {
    id: 'ZI_YmEEkmekLahmacunYmS', 
    purpose: #STANDARD, 
    type: #LINEITEM_REFERENCE, 
    label: 'YM E.Ekmek-Lahmacun YM Stok Tabl.', 
    position: 1 , 
    targetElement: '_YmEEkmekLahmacunYmS'
  } ]
  @UI.lineItem: [ {
    position: 1 
  } ]
  key 1 as SingletonID,
  _YmEEkmekLahmacunYmS,
  @UI.hidden: true
  I_CstmBizConfignLastChgd.LastChangedDateTime as LastChangedAtMax
}
where I_Language.Language = $session.system_language
