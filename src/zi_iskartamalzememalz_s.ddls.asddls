@EndUserText.label: 'Iskarta Malzeme Malz. Singleton'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.semanticKey: [ 'SingletonID' ]
@UI: {
  headerInfo: {
    typeName: 'IskartaMalzemeMaAll'
  }
}
define root view entity ZI_IskartaMalzemeMalz_S
  as select from I_Language
    left outer join I_CstmBizConfignLastChgd on I_CstmBizConfignLastChgd.ViewEntityName = 'ZI_ISKARTAMALZEMEMALZ'
  composition [0..*] of ZI_IskartaMalzemeMalz as _IskartaMalzemeMalz
{
  @UI.facet: [ {
    id: 'ZI_IskartaMalzemeMalz', 
    purpose: #STANDARD, 
    type: #LINEITEM_REFERENCE, 
    label: 'Iskarta Malzeme Malz.', 
    position: 1 , 
    targetElement: '_IskartaMalzemeMalz'
  } ]
  @UI.lineItem: [ {
    position: 1 
  } ]
  key 1 as SingletonID,
  _IskartaMalzemeMalz,
  @UI.hidden: true
  I_CstmBizConfignLastChgd.LastChangedDateTime as LastChangedAtMax
}
where I_Language.Language = $session.system_language
