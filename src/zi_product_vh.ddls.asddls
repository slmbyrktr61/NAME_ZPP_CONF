@EndUserText.label: 'Ürün Value Help'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.ignorePropagatedAnnotations: true

@ObjectModel.dataCategory: #VALUE_HELP
@ObjectModel.representativeKey: 'Product'
@ObjectModel.supportedCapabilities: [#VALUE_HELP_PROVIDER]

@Search.searchable: true
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

define view entity ZI_PRODUCT_VH
  as select from I_Product as _Product
    left outer join zpp_t_conf_010 as _materialtype on _materialtype.malzeme = _Product.Product

  association [0..1] to I_ProductText       as _ProductText on  _Product.Product      = _ProductText.Product
                                                            and _ProductText.Language = $session.system_language
  association [0..1] to I_ProductPlantBasic as _PlantBasic  on  _PlantBasic.Product = _Product.Product

{
      @EndUserText.label: 'Malzeme'
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      @ObjectModel.text.element: [ 'ProductName' ]
  key ltrim( _Product.Product, '0' )                      as Product,

      @EndUserText.label: 'Malzeme Tanımı'
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      @Semantics.text: true
      _ProductText.ProductName                            as ProductName,
      _Product.BaseUnit,
      @EndUserText.label: 'Malzeme Türü'
      _materialtype.uretimturu as ProductionType,
      @EndUserText.label: 'Depo Yeri'
      _PlantBasic.ProductionInvtryManagedLoc as StorageLoc,
      _Product.IsBatchManagementRequired as IsBatchManagementRequired,
      _Product.ProductType as ProductType

}
