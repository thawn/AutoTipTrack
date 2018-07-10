function String = printPercentageWithError(Fraction, N)
if Fraction <= 0 || Fraction >=1
  Error = sqrt(N)/N;
else
  Error = sqrt(Fraction * (1 - Fraction) / N);
end
Precision = ceil(-log10(Error)) - 2;
if Precision < 0
  Precision = 0;
elseif Precision > 10
  Precision = 10;
end
FormatStr = sprintf('%% 3.%df %s %%.%df%%%%',Precision,177,Precision + 1);
String = sprintf(FormatStr, Fraction * 100, Error * 100);
end
