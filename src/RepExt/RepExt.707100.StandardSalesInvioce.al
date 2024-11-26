reportextension 70100 "Standard Sales Invoice" extends "Standard Sales - Invoice"
{
    dataset
    {
        add(Header)
        {
            column(WarrantyLaborlbl; WarrantyLaborlbl) { }
            column(WarrantyPartslbl; WarrantyPartslbl) { }
        }
        add(Line)
        {
            column(Warranty_End_Date_Labor; "Warranty End Date Labor") { }
            column(Warranty_End_Date_parts; "Warranty End Date parts") { }
        }
    }

    rendering
    {
        layout("Posted Sales Invoice")
        {
            Type = RDLC;
            LayoutFile = 'src/Layouts/StandardSalesInvoice.rdl';
        }
    }
    var
        WarrantyLaborlbl: label 'Labor Warranty';
        WarrantyPartslbl: Label 'Parts Warranty';
}