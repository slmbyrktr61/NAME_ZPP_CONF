@EndUserText.label: 'Iskarta Malzeme Malz. Singleton'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.semanticKey: [ 'SingletonID' ]
@UI: {
  headerInfo: {
    typeName: 'IskartaMalzemeMaAll'
  }
}
define root view entity ZI_ISKARTAMALZEME_S
  as select from I_Language
    left outer join I_CstmBizConfignLastChgd on I_CstmBizConfignLastChgd.ViewEntityName = 'ZI_IISKARTAMALZEME'
  composition [0..*] of ZI_IISKARTAMALZEME as _IskartaMalzeme
{
  @UI.facet: [ {
    id: 'ZI_IISKARTAMALZEME', 
    purpose: #STANDARD, 
    type: #LINEITEM_REFERENCE, 
    label: 'Iskarta Malzeme Malz.', 
    position: 1 , 
    targetElement: '_IskartaMalzeme'
  } ]
  @UI.lineItem: [ {
    position: 1 
  } ]
  key 1 as SingletonID,
  _IskartaMalzeme,
  @UI.hidden: true
  I_CstmBizConfignLastChgd.LastChangedDateTime as LastChangedAtMax
}
where I_Language.Language = $session.system_language
