@EndUserText.label: 'Tüketim Stokta Kalacak Miktarlar Tabl.'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.semanticKey: [ 'SingletonID' ]
@UI: {
  headerInfo: {
    typeName: 'TKetimStoktaKalaAll'
  }
}
define root view entity ZI_TKetimStoktaKalacak_S14
  as select from I_Language
    left outer join I_CstmBizConfignLastChgd on I_CstmBizConfignLastChgd.ViewEntityName = 'ZI_TKETIMSTOKTAKALACAK'
  composition [0..*] of ZI_TKetimStoktaKalacak as _TKetimStoktaKalacak
{
  @UI.facet: [ {
    id: 'ZI_TKetimStoktaKalacak', 
    purpose: #STANDARD, 
    type: #LINEITEM_REFERENCE, 
    label: 'Tüketim Stokta Kalacak Miktarlar Tabl.', 
    position: 1 , 
    targetElement: '_TKetimStoktaKalacak'
  } ]
  @UI.lineItem: [ {
    position: 1 
  } ]
  key 1 as SingletonID,
  _TKetimStoktaKalacak,
  @UI.hidden: true
  I_CstmBizConfignLastChgd.LastChangedDateTime as LastChangedAtMax
}
where I_Language.Language = $session.system_language
