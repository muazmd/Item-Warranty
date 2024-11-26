pageextension 70104 "P. Sales Invoice Subform" extends "posted Sales Invoice Subform"
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


}