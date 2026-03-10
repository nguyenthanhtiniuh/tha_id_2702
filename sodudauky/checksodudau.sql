SELECT *
FROM B32005OpenBalance
WHERE DebitAmount % 1 <> 0
      OR CreditAmount % 1 <> 0
      OR DebitYearBal % 1 <> 0
      OR CreditYearBal % 1 <> 0
ORDER BY ModifiedAt DESC

