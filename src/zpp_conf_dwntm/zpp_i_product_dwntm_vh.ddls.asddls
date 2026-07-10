@EndUserText.label: 'Duruş Mamul Malz.'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.ignorePropagatedAnnotations: true

@ObjectModel.dataCategory: #VALUE_HELP
@ObjectModel.representativeKey: 'Product'
@ObjectModel.supportedCapabilities: [#VALUE_HELP_PROVIDER]

@UI.presentationVariant: [
  {
    sortOrder: [
      {
        by: 'Product',
        direction: #ASC
      }
    ]
  }
]

define view entity ZPP_I_PRODUCT_DWNTM_VH
  as select from    I_Product      as _Product
  association [0..1] to I_ProductText       as _ProductText
    on  _Product.Product      = _ProductText.Product
    and _ProductText.Language = $session.system_language

{
      @EndUserText.label: 'Malzeme'
      // Genel Arama alanını beslediği için kapatıldı
      // @Search.defaultSearchElement: true
      // @Search.fuzzinessThreshold: 0.8
      @ObjectModel.text.element: [ 'ProductName' ]
      @UI.selectionField: [{ position: 10 }]
  key ltrim( _Product.Product, '0' ) as Product,

      @EndUserText.label: 'Malzeme Tanımı'
      // Genel Arama alanını beslediği için kapatıldı
      // @Search.defaultSearchElement: true
      // @Search.fuzzinessThreshold: 0.8
      @Semantics.text: true
      @UI.selectionField: [{ position: 20 }]
      _ProductText.ProductName as ProductName,

      @EndUserText.label: 'Temel ölçü birimi'
      @UI.selectionField: [{ position: 30 }]
      _Product.BaseUnit,

      _Product.ProductType as ProductType
}
where _Product.ProductType = '1003'
