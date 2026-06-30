@EndUserText.label: 'YM Börek Üretiminde Çarpan Sayı Singleto'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.semanticKey: [ 'SingletonID' ]
@UI: {
  headerInfo: {
    typeName: 'YmBRekRetimindeAAll'
  }
}
define root view entity ZI_YmBRekRetimindcArpa_S
  as select from I_Language
    left outer join I_CstmBizConfignLastChgd on I_CstmBizConfignLastChgd.ViewEntityName = 'ZI_YMBREKRETIMINDEARPAN'
  composition [0..*] of ZI_YmBRekRetimindeArpan as _YmBRekRetimindArpan
{
  @UI.facet: [ {
    id: 'ZI_YmBRekRetimindeArpan', 
    purpose: #STANDARD, 
    type: #LINEITEM_REFERENCE, 
    label: 'YM Börek Üretiminde Çarpan Sayı', 
    position: 1 , 
    targetElement: '_YmBRekRetimindArpan'
  } ]
  @UI.lineItem: [ {
    position: 1 
  } ]
  key 1 as SingletonID,
  _YmBRekRetimindArpan,
  @UI.hidden: true
  I_CstmBizConfignLastChgd.LastChangedDateTime as LastChangedAtMax
}
where I_Language.Language = $session.system_language
