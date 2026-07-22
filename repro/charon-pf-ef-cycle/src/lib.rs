use field::{ExtensionField, Field, PrimeCharacteristicRing};

pub type PF<F> = <F as PrimeCharacteristicRing>::PrimeSubfield;

pub fn pf_associated_projection_case<EF: ExtensionField<PF<EF>>>(x: EF) -> EF {
    x
}

pub fn explicit_self_base_case<EF: ExtensionField<EF>>(x: EF) -> EF {
    x
}

pub fn explicit_generic_base_case<EF, Base>(x: EF) -> EF
where
    Base: Field,
    EF: ExtensionField<Base>,
{
    x
}
