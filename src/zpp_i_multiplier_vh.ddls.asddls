@EndUserText.label: 'Çarpan VH'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.ignorePropagatedAnnotations: true

@ObjectModel.resultSet.sizeCategory: #XS
@ObjectModel.dataCategory: #VALUE_HELP
@ObjectModel.representativeKey: 'Carpan'
@ObjectModel.supportedCapabilities: [#VALUE_HELP_PROVIDER]

@Search.searchable: true
@UI.presentationVariant: [
  {
    sortOrder: [
      {
        by: 'Carpan',
        direction: #ASC
      }
    ]
  }
]
define view entity ZPP_I_MULTIPLIER_VH
  as select from zpp_t_conf_005
{
      @EndUserText.label: 'Çarpan'
      @Search.defaultSearchElement: true
      @UI.lineItem: [{ position: 10, label: 'Çarpan' }]
  key carpan as Carpan
}
