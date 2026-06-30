@EndUserText.label: 'YM Börek Üretim YM Tüketim Tabl. Singlet'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.semanticKey: [ 'SingletonID' ]
@UI: {
  headerInfo: {
    typeName: 'YmBRekRetimYmTKeAll'
  }
}
define root view entity ZI_YmBRekRetimYmTKetim_S
  as select from I_Language
    left outer join I_CstmBizConfignLastChgd on I_CstmBizConfignLastChgd.ViewEntityName = 'ZI_YMBREKRETIMYMTKETIM'
  composition [0..*] of ZI_YmBRekRetimYmTKetim as _YmBRekRetimYmTKetim
{
  @UI.facet: [ {
    id: 'ZI_YmBRekRetimYmTKetim', 
    purpose: #STANDARD, 
    type: #LINEITEM_REFERENCE, 
    label: 'YM Börek Üretim YM Tüketim Tabl.', 
    position: 1 , 
    targetElement: '_YmBRekRetimYmTKetim'
  } ]
  @UI.lineItem: [ {
    position: 1 
  } ]
  key 1 as SingletonID,
  _YmBRekRetimYmTKetim,
  @UI.hidden: true
  I_CstmBizConfignLastChgd.LastChangedDateTime as LastChangedAtMax
}
where I_Language.Language = $session.system_language
