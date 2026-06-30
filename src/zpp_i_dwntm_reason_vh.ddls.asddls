@EndUserText.label: 'Duruş Kodu Sebebi VH'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.ignorePropagatedAnnotations: true

@ObjectModel.dataCategory: #VALUE_HELP
@ObjectModel.representativeKey: 'DowntimeCode'
@ObjectModel.supportedCapabilities: [#VALUE_HELP_PROVIDER]
@ObjectModel.resultSet.sizeCategory: #XS

@Search.searchable: true
define view entity ZPP_I_DWNTM_REASON_VH
  as select from zpp_t_conf_007
{
      @EndUserText.label: 'Duruş Kodu'
      @Search.defaultSearchElement: true
      @ObjectModel.text.element: [ 'DowntimeReason' ]
  key duruskodu as DowntimeCode,

      @EndUserText.label: 'Duruş Sebebi'
      @Search.defaultSearchElement: true
      @Semantics.text: true
      durussebebi as DowntimeReason
}
