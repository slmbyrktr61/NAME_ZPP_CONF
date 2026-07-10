@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Teyit Başlık Root Entity'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZPP_I_CONF_H
  as select from    zpp_t_conf_h           as h
    left outer join I_Product              as p on p.Product = cast(
      lpad(
        h.material, 18, '0'
      )                                    as matnr
    )
    left outer join ZI_MalzemeArjMiktarTab as s on s.Malzeme = cast(
      lpad(
        h.material, 18, '0'
      )                                    as matnr
    )

  association [0..1] to ZPP_I_SHIFT_VH as _ShiftVH on $projection.ShiftCode = _ShiftVH.ShiftCode

  association [0..1] to ZPP_I_GROUP_VH as _GroupVH on $projection.GroupCode = _GroupVH.GroupCode

  composition [0..*] of ZPP_I_CONF_I   as _Items

{
  key h.conf_uuid             as ConfUuid,

      h.plant                 as Plant,

      @ObjectModel.text.element: [ 'ShiftDesc' ]
      h.shiftcode             as ShiftCode,

      _ShiftVH.ShiftDesc      as ShiftDesc,

      @ObjectModel.text.element: [ 'GroupDesc' ]
      h.groupcode             as GroupCode,

      _GroupVH.GroupDesc      as GroupDesc,

      h.material              as Material,
      h.material_description  as MaterialDescription,

      @Semantics.quantity.unitOfMeasure: 'BaseUnit'
      h.production_quantity   as ProductionQuantity,

      @Semantics.quantity.unitOfMeasure: 'BaseUnit'
      h.actual_quantity       as ActualQuantity,

      h.charge_quantity       as ChargeQuantity,

      //      cast( '' as abap_boolean ) as HideChargeQuantity,
      case
       when s.Sarjmiktari > 0
       then cast( '' as abap_boolean )
       else cast( 'X' as abap_boolean )
      end                     as HideChargeQuantity,

      h.multiplier            as Multiplier,
      case
       when h.production_type = 'YM_BOREK'
       then cast( '' as abap_boolean )
       else cast( 'X' as abap_boolean )
      end                     as HideMultiplier,

      h.base_unit             as BaseUnit,

      h.production_batch      as ProductionBatch,

      h.production_type       as ProductionType,
      h.production_version    as ProductionVersion,

      h.closing_shift         as ClosingShift,

      case
        when h.production_type = 'MAMUL_EE_LAHMACUN'
          or h.production_type = 'YM_EE_LAHMACUN'
          or h.production_type = 'YM_BOREK'
        then cast( '' as abap_boolean )
        else cast( 'X' as abap_boolean )
      end                     as HideClosingShift,

      h.conf_doc              as ConfDoc,
      h.batch_update          as BatchUpdate,

      h.downtime              as Downtime,
//      case
//      when h.material is initial
//      then cast( 'X' as abap_boolean )
//      when p.ProductType = '1003'
//      then cast( '' as abap_boolean )
//      else cast( 'X' as abap_boolean )
//      end                     
      h.hide_downtime as HideDowntime,

      @Semantics.user.createdBy: true
      h.created_by            as CreatedBy,

      @Semantics.systemDateTime.createdAt: true
      h.created_at            as CreatedAt,

      @Semantics.user.lastChangedBy: true
      h.last_changed_by       as LastChangedBy,

      @Semantics.systemDateTime.lastChangedAt: true
      h.last_changed_at       as LastChangedAt,

      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      h.local_last_changed_at as LocalLastChangedAt,

      _Items,
      _ShiftVH,
      _GroupVH
}
//where h.conf_doc is initial
