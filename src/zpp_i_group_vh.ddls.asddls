//@EndUserText.label: 'Grup Seçimi VH'
//@AccessControl.authorizationCheck: #NOT_REQUIRED
//@Metadata.ignorePropagatedAnnotations: true
//
//@ObjectModel.dataCategory: #VALUE_HELP
//@ObjectModel.representativeKey: 'GroupCode'
//@ObjectModel.supportedCapabilities: [#VALUE_HELP_PROVIDER]
//
//@Search.searchable: true
//@UI.presentationVariant: [
//  {
//    sortOrder: [
//      {
//        by: 'GroupCode',
//        direction: #ASC
//      }
//    ]
//  }
//]
//
//define view entity ZPP_I_GROUP_VH
//  as select from zpp_t_conf_002
//{
//      @EndUserText.label: 'Grup Kodu'
//      @Search.defaultSearchElement: true
//      @Search.fuzzinessThreshold: 0.8
//      @ObjectModel.text.element: [ 'GroupCode' ]
//      key grup as GroupCode,
//
//      @EndUserText.label: 'Grup Tanımı'
//      @Search.defaultSearchElement: true
//      @Search.fuzzinessThreshold: 0.8
//      @Semantics.text: true
//      tanim as GroupDesc
//}


@EndUserText.label: 'Grup Seçimi VH'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.ignorePropagatedAnnotations: true

@ObjectModel.resultSet.sizeCategory: #XS
@ObjectModel.dataCategory: #VALUE_HELP
@ObjectModel.representativeKey: 'GroupCode'
@ObjectModel.supportedCapabilities: [#VALUE_HELP_PROVIDER]

@Search.searchable: true
@UI.presentationVariant: [
  {
    sortOrder: [
      {
        by: 'GroupCode',
        direction: #ASC
      }
    ]
  }
]

define view entity ZPP_I_GROUP_VH
  as select from zpp_t_conf_002
{
      @EndUserText.label: 'Grup Kodu'
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      @ObjectModel.text.element: [ 'GroupDesc' ]
  key grup  as GroupCode,

      @EndUserText.label: 'Grup Tanımı'
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      @Semantics.text: true
      tanim as GroupDesc
}
