@EndUserText.label: 'Malzeme Üretim Türü Tabl.'
@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
define view entity ZI_MalzemeRetimTRTabl
  as select from zpp_t_conf_010
  association to parent ZI_MalzemeRetimTRTabl_S as _MalzemeRetimTRTaAll on $projection.SingletonID = _MalzemeRetimTRTaAll.SingletonID
{
  @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_PRODUCT_VH', element: 'Product'} }]
  key malzeme    as Malzeme,
  

   @Consumption.valueHelpDefinition: [
    {
      entity: {
        name: 'ZPP_I_PROD_TYPE_VH',
        element: 'ProductionType'
      }
    }
  ]
      uretimturu as Uretimturu,
      @Consumption.hidden: true
      1          as SingletonID,
      _MalzemeRetimTRTaAll
      
}
