@EndUserText.label: 'Vardiya Seçimi VH'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.ignorePropagatedAnnotations: true

@ObjectModel.resultSet.sizeCategory: #XS
@Search.searchable: true
@ObjectModel.dataCategory: #VALUE_HELP
@ObjectModel.representativeKey: 'ShiftCode'
@ObjectModel.supportedCapabilities: [#VALUE_HELP_PROVIDER]

define view entity ZPP_I_SHIFT_VH
  as select from zpp_t_conf_001
{
      @EndUserText.label: 'Vardiya Kodu'
      @Search.defaultSearchElement: true
      @ObjectModel.text.element: [ 'ShiftDesc' ]
      key shiftno as ShiftCode,

      @EndUserText.label: 'Vardiya Tanımı'
      @Semantics.text: true
      shiftdesc as ShiftDesc
}
