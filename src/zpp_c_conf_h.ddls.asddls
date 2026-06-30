@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Teyit Başlık Projection Entity'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define root view entity ZPP_C_CONF_H
  provider contract transactional_query
  as projection on ZPP_I_CONF_H
{
  key ConfUuid,

      Plant,

      @ObjectModel.text.element: [ 'ShiftDesc' ]
      ShiftCode,

      ShiftDesc,

      @ObjectModel.text.element: [ 'GroupDesc' ]
      GroupCode,

      GroupDesc,

      Material,
      MaterialDescription,

      @Semantics.quantity.unitOfMeasure: 'BaseUnit'
      ProductionQuantity,

      @Semantics.quantity.unitOfMeasure: 'BaseUnit'
      ActualQuantity,      
//      HideActualQuantity,

      ChargeQuantity,
      HideChargeQuantity,

      Multiplier,
      HideMultiplier,

      @Semantics.unitOfMeasure
      BaseUnit,

      ProductionBatch,
      ProductionType,
      ProductionVersion,
      ClosingShift,
      HideClosingShift,
      ConfDoc,
      BatchUpdate,

      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChangedAt,

      _Items : redirected to composition child ZPP_C_CONF_I
}
