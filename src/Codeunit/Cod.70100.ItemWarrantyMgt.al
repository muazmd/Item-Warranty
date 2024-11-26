
// This codeunit manages the warranty information for items,
codeunit 70100 "Item Warranty Mgt."
{

    [EventSubscriber(ObjectType::table, Database::Item, OnAfterValidateEvent, 'Item Category Code', False, False)]
    local procedure AutoPopulateWarrantyInfo(var Rec: Record Item; var xRec: Record Item; CurrFieldNo: Integer)
    var
        ItemCategory: Record "Item Category";
    begin
        //This procedure auto-populates the warranty durations on the Item card
        // when the "Item Category Code" field is changed.
        if rec."Item Category Code" <> xrec."Item Category Code" then begin // Only proceed if the Item Category Code has changed.
            if ItemCategory.get(rec."Item Category Code") then begin

                // Copy the warranty durations from the Item Category to the Item.
                rec."B2B Warranty Duration Labor" := ItemCategory."B2B Warranty Duration Labor";
                rec."B2B Warranty Duration Parts" := ItemCategory."B2B Warranty Duration Parts";
                rec."B2C Warranty Duration Labor" := ItemCategory."B2C Warranty Duration Labor";
                rec."B2C Warranty Duration Parts" := ItemCategory."B2C Warranty Duration Parts";
            end;
        end;
    end;

    [EventSubscriber(ObjectType::table, Database::"Sales Header", OnAfterInsertTempSalesLine, '', False, False)]
    local procedure PreserveLinkedToTempLine(SalesLine: Record "Sales Line"; var TempSalesLine: Record "Sales Line" temporary)
    begin
        TempSalesLine."Linked Sales Line" := SalesLine."Linked Sales Line";

    end;

    [EventSubscriber(ObjectType::table, Database::"Sales Header", OnAfterRecreateSalesLine, '', False, False)]
    local procedure PreserveLinkedToLine(SalesLine: Record "Sales Line"; var TempSalesLine: Record "Sales Line" temporary)
    begin
        SalesLine."Linked Sales Line" := TempSalesLine."Linked Sales Line";
        SalesLine.Modify()

    end;


    [EventSubscriber(ObjectType::table, Database::"Sales Header", OnAfterValidateEvent, 'Sell-to Customer No.', False, False)]
    local procedure CheckForCustomerType(var Rec: Record "Sales Header"; var xRec: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        OriginalSalesLine: Record "Sales Line";
    begin
        // This Procedure will rerun the Sales lines Validation to calculate the warranty dates based on customer type
        if rec."Sell-to Customer No." <> xRec."Sell-to Customer No." then begin
            SalesLine.SetRange("Document No.", rec."No.");
            SalesLine.SetRange("Document Type", rec."Document Type");
            if SalesLine.FindSet(true) then
                repeat
                    if SalesLine.Type = SalesLine.Type::item then begin
                        if SalesLine."Linked Sales Line" <> 0 then begin
                            if OriginalSalesLine.get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Linked Sales Line") then begin
                                CalcExtendedWarranty(OriginalSalesLine, SalesLine);
                                ClearWarrantyDate(SalesLine);
                            end;
                        end;
                    end;
                until SalesLine.next = 0;
        end;
    end;

    [EventSubscriber(ObjectType::table, Database::"Sales Line", OnAfterValidateEvent, 'No.', False, False)]
    local procedure CalculateWarrantyDatesOnValidate(CurrFieldNo: Integer; var Rec: Record "Sales Line"; var xRec: Record "Sales Line")
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
    begin

        // This procedure calculates the warranty end dates on the Sales Line when the Item No. is validated 

        if rec."No." <> xRec."No." then begin
            if SalesHeader.get(rec."Document Type", rec."Document No.") then;
            SalesHeader.TestField("Posting Date");
            if rec.Type = rec.Type::Item then begin
                if item.get(rec."No.") then begin

                    rec."B2B Warranty Duration Labor" := item."B2B Warranty Duration Labor";
                    rec."B2B Warranty Duration Parts" := item."B2B Warranty Duration Parts";
                    rec."B2C Warranty Duration Labor" := item."B2C Warranty Duration Labor";
                    rec."B2C Warranty Duration Parts" := item."B2C Warranty Duration Parts";

                    // Calculate the warranty end dates based on the durations.
                    CalcWarrantyDate(SalesHeader, Rec);
                end;
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", OnAfterValidateEvent, 'Posting Date', False, False)]
    local procedure UpdateWarrantyDatesOnPostingDate(var Rec: Record "Sales Header"; var xRec: Record "Sales Header")
    begin

        // This procedure updates the warranty end dates on all Sales Lines
        // when the Posting Date on the Sales Header is changed.
        rec.TestField("Posting Date");
        if rec."Posting Date" <> xRec."Posting Date" then begin
            UpdateWarrantyDates(rec);
        end;
    end;

    local procedure CalcWarrantyDate(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
    begin
        // This procedure calculates the Warranty End Dates for Labor and Parts 
        // based on the warranty durations and the Posting Date.
        if SalesHeader."VAT Registration No." <> '' then begin   // If the customer has a VAT Registration No., they are considered B2B.
            SalesLine."Warranty End Date Labor" := CalcDate(Format(SalesLine."B2B Warranty Duration Labor") + 'M', SalesHeader."Posting Date");
            SalesLine."Warranty End Date Parts" := CalcDate(Format(SalesLine."B2B Warranty Duration Parts") + 'M', SalesHeader."Posting Date");
        end
        else begin    // If there is no VAT Registration No., the customer is considered B2C
            SalesLine."Warranty End Date Labor" := CalcDate(Format(SalesLine."B2C Warranty Duration Labor") + 'M', SalesHeader."Posting Date");
            SalesLine."Warranty End Date Parts" := CalcDate(Format(SalesLine."B2C Warranty Duration Parts") + 'M', SalesHeader."Posting Date");
        end;
    end;


    procedure SelectExtendedWarranty(SalesLine: Record "Sales Line")
    var
        ItemSelection: page "Item Lookup";
        Item: Record item;
        NewSaleline: Record "Sales Line";
    begin
        // This procedure allows the user to select an Extended Warranty item
        // and adds it to the Sales Line, linking it to the original item.
        SalesLine.TestField("No.");
        if SalesLine.Type = SalesLine.Type::Item then begin

            ItemSelection.LookupMode := true;
            if ItemSelection.RunModal() = Action::LookupOK then begin
                ItemSelection.GetRecord(Item);
                NewSaleline.Init();
                NewSaleline.TransferFields(SalesLine);
                NewSaleline.Validate("No.", Item."No.");
                NewSaleline."Line No." := GetNextLineNo(SalesLine);
                NewSaleline."Linked Sales Line" := SalesLine."Line No.";
                NewSaleline.Validate(Quantity, 1);
                NewSaleline.Insert(true);
                CalcExtendedWarranty(SalesLine, NewSaleline);
                ClearWarrantyDate(NewSaleline);
            end;
        end;
    end;

    local procedure GetNextLineNo(SalesLine: Record "Sales Line"): Integer
    var
        LastLine: Record "Sales Line";
    begin

        // This procedure calculates the next available Line No. for adding a new Sales Line. 
        // incrementing the line No. by 1, allowing the users to add more than one extended warranty

        LastLine.SetRange("Linked Sales Line", SalesLine."Line No.");
        LastLine.SetRange("Document No.", SalesLine."Document No.");
        LastLine.SetRange("Document Type", SalesLine."Document Type");
        if LastLine.FindLast() then
            exit(LastLine."Line No." + 1)
        else
            exit(SalesLine."Line No." + 1);
    end;

    local procedure ClearWarrantyDate(SaleLine: Record "Sales Line")
    var
    begin

        // This procedure clears the Warranty End Dates on the Extended Warranty line,
        // as the extended warranty affects the original item, not the warranty item itself.
        SaleLine."Warranty End Date Labor" := 0D;
        SaleLine."Warranty End Date parts" := 0D;
        SaleLine.Modify();
    end;

    local procedure CalcExtendedWarranty(SalesLine: Record "Sales Line"; ExtendedSalesLine: Record "Sales Line")
    var
        NewWarrantyPeriod: Integer;
        SalesHeader: Record "Sales Header";
    begin

        // This procedure updates the warranty duration and end date on the original Sales Line
        // when an Extended Warranty is added.
        if SalesHeader.get(SalesLine."Document Type", SalesLine."Document No.") then;
        if SalesHeader."VAT Registration No." <> '' then begin
            NewWarrantyPeriod := SalesLine."B2B Warranty Duration Labor" + ExtendedSalesLine."B2B Warranty Duration Labor";// Calculate the new total Labor Warranty Duration for B2B.
            SalesLine."B2B Warranty Duration Labor" := NewWarrantyPeriod;
        end
        else begin
            NewWarrantyPeriod := SalesLine."B2C Warranty Duration Labor" + ExtendedSalesLine."B2C Warranty Duration Labor";// Calculate the new total Labor Warranty Duration for B2C.
            SalesLine."B2C Warranty Duration Labor" := NewWarrantyPeriod;
        end;
        SalesLine."Warranty End Date Labor" := CalcDate(Format(NewWarrantyPeriod) + 'M', SalesHeader."Posting Date");
        SalesLine.Modify();
    end;

    procedure UpdateWarrantyDates(SalesHeader: Record "Sales Header")
    var
        SalesLines: Record "Sales Line";
    begin
        // This procedure updates the warranty end dates on all Sales Lines associated with a Sales Header,
        // called when the Posting Date is changed.
        SalesLines.SetRange("Document No.", SalesHeader."No.");
        SalesLines.SetRange("Document Type", SalesHeader."Document Type");
        if SalesLines.FindSet(true) then
            repeat
                CalcWarrantyDate(SalesHeader, SalesLines);
                SalesLines.Modify();
            until SalesLines.next = 0;
    end;

    procedure ProcessLineDeletion(SalesLine: Record "Sales Line")
    var
        SalesHeader: Record "Sales Header";
    begin
        // This procedure handles the deletion of an Extended Warranty line or Line with Linked Extended Warranty
        // and adjusts the warranty durations on the original item line accordingly or Delete All Linked Lines
        if SalesLine."Document Type" in [SalesLine."Document Type"::Order, SalesLine."Document Type"::Invoice] then begin
            if SalesLine."Linked Sales Line" <> 0 then begin
                // If the Sales Line is an Extended Warranty (it is linked to another line).
                HandleExtendedLineDeleted(SalesLine, SalesHeader);
            end
            else
                // If the Sales Line has Lines linked to it
                HandleOriginalLineDeleted(SalesLine);
        end;
    end;


    local procedure HandleExtendedLineDeleted(SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    var
        OriginalSalesLine: Record "Sales Line";
        OriginalWarrantyPeriod: Integer;
    begin
        // This procedure adjusts the original item line's warranty durations
        // when an Extended Warranty line is deleted.

        //Find the Original Line this Line is Linked to
        OriginalSalesLine.SetRange("Document Type", SalesLine."Document Type");
        OriginalSalesLine.SetRange("Document No.", SalesLine."Document No.");
        OriginalSalesLine.SetRange("Line No.", SalesLine."Linked Sales Line");
        if OriginalSalesLine.FindFirst() then begin
            SalesHeader.get(SalesLine."Document Type", SalesLine."Document No.");
            if SalesHeader."VAT Registration No." <> '' then begin
                // Subtract the Extended Warranty duration from the original Labor Warranty Duration.
                OriginalWarrantyPeriod := OriginalSalesLine."B2B Warranty Duration Labor" - SalesLine."B2B Warranty Duration Labor";
            end
            else begin
                // Subtract the Extended Warranty duration from the original Labor Warranty Duration.
                OriginalWarrantyPeriod := OriginalSalesLine."B2C Warranty Duration Labor" - SalesLine."B2C Warranty Duration Labor";
            end;
            OriginalSalesLine."Warranty End Date Labor" := CalcDate(Format(OriginalWarrantyPeriod) + 'M', SalesHeader."Posting Date");
            OriginalSalesLine.Modify();
        end;
    end;

    //Check all linked lines to this line and delete
    local procedure HandleOriginalLineDeleted(SalesLine: Record "Sales Line")
    var
        ExtendedSalesLine: Record "Sales Line";
    begin
        // This procedure deletes all Extended Warranty lines linked to an original item line
        // when the original line is deleted.
        if SalesLine."Document Type" in [SalesLine."Document Type"::Order, SalesLine."Document Type"::Invoice] then begin

            SalesLine.SetRange("Document Type", SalesLine."Document Type");
            SalesLine.SetRange("Document No.", SalesLine."Document No.");
            SalesLine.SetRange("Linked Sales Line", SalesLine."Line No.");
            if SalesLine.FindSet() then
                repeat
                    SalesLine.Delete();
                until SalesLine.next = 0;
        end;
    end;

}