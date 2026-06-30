@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Teyit Kalem Entity'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZPP_I_CONF_I
  as select from zpp_t_conf_i
  association to parent ZPP_I_CONF_H as _Header on $projection.ConfUuid = _Header.ConfUuid
{
  key item_uuid                  as ItemUuid,

      conf_uuid                  as ConfUuid,
      item_no                    as ItemNo,
      component_material         as ComponentMaterial,
      component_description      as ComponentDescription,

      storage_location           as StorageLocation,
      batch                      as Batch,

      @Semantics.quantity.unitOfMeasure: 'Unit'
      quantity                   as Quantity,

      unit                       as Unit,

      car_count                  as CarCount,

      actual_stock_quantity      as ActualStockQuantity,

      hide_actual_stock_quantity as HideActualStockQuantity,

      bom_item_cat               as BomItemCat,

      is_batch_mngmnt_required   as IsBatchMngmntRequired,

      local_last_changed_at      as LocalLastChangedAt,

      _Header

}
