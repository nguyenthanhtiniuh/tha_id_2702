SELECT * FROM B32002AccDoc CT WHERE CT.Stt='I230094835'

-------
SELECT CT.DocCode, CT.TransCode, CT.DebitAccount, CT.CreditAccount, OriginalAmount9, CT.Description
FROM vB32002AccDocCashPayment_Edit CT
WHERE CT.Stt='I230094835'