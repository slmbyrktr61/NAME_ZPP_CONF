@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Üretim Türü VH'
@Metadata.ignorePropagatedAnnotations: true

@ObjectModel.dataCategory: #VALUE_HELP
@ObjectModel.representativeKey: 'ProductionType'
@ObjectModel.supportedCapabilities: [#VALUE_HELP_PROVIDER]

@Search.searchable: true
@UI.presentationVariant: [
  {
    sortOrder: [
      {
        by: 'ProductionType',
        direction: #ASC
      }
    ]
  }
]
define view entity ZPP_I_PROD_TYPE_VH
  as select from zpp_t_conf_013
{
      @EndUserText.label: 'Üretim Türü'
      @Search.defaultSearchElement: true
  key uretimturu as ProductionType
}
