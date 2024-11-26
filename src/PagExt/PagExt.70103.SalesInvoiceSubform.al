pageextension 70103 "Sales Invoice Subform" extends "Sales Invoice Subform"
{
    layout
    {
        addafter(Quantity)
        {
            field("Warranty End Date Labor"; Rec."Warranty End Date Labor")
            {
                ApplicationArea = all;
                Editable = false;

            }
            field("Warranty End Date parts"; Rec."Warranty End Date parts")
            {
                ApplicationArea = all;
                Editable = false;
            }
        }
    }
    actions
    {
        addfirst("F&unctions")
        {
            action("Select Extended Warranty")
            {
                ApplicationArea = all;
                trigger OnAction()
                var
                    WarantyMgt: Codeunit "Item Warranty Mgt.";
                begin
                    WarantyMgt.SelectExtendedWarranty(rec);
                end;
            }
        }
    }

}