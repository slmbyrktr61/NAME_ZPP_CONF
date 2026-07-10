@EndUserText.label: 'Ürün Value Help'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.ignorePropagatedAnnotations: true

@ObjectModel.dataCategory: #VALUE_HELP
@ObjectModel.representativeKey: 'Product'
@ObjectModel.supportedCapabilities: [#VALUE_HELP_PROVIDER]

// Genel Arama alanını açtığı için kapatıldı
// @Search.searchable: true

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

define view entity ZPP_I_PRODUCT_VH
  as select from    I_Product      as _Product
    left outer join zpp_t_conf_010 as _materialtype
      on _materialtype.malzeme = _Product.Product

  association [0..1] to I_ProductText       as _ProductText
    on  _Product.Product      = _ProductText.Product
    and _ProductText.Language = $session.system_language

  association [0..1] to I_ProductPlantBasic as _PlantBasic
    on _PlantBasic.Product = _Product.Product

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

      @EndUserText.label: 'Malzeme Üretim Türü'
      @UI.selectionField: [{ position: 40 }]
      _materialtype.uretimturu as MaterialType,

      @EndUserText.label: 'Depo Yeri'
      @UI.selectionField: [{ position: 50 }]
      _PlantBasic.ProductionInvtryManagedLoc as StorageLoc,
      _Product.ProductType as ProductType
}
