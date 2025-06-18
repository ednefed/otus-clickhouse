#!/usr/bin/env bash

set -o errexit

while read -r input; do
	quantity=${input%%,*}
	price=${input#*,}

	# Найдём целую часть и дробную для перевода цены в целые копейки
	if [[ "$price" =~ \. ]]; then
		integer=${price%%.*}
		fraction=${price#*.}

		if [[ $fraction -lt 10 ]]; then
			fraction="${fraction}0"
		fi
	else
		integer=$price
		fraction=00
	fi

	# Переводим в целые копейки
	price_cents="$integer$fraction"
	# Считаем сумму в копейках
	total_cents=$(( quantity * price_cents ))
	# Выводим результат как Decimal(2)
	printf "%s.%s\n" "${total_cents::-2}" "${total_cents:(-2)}"
done
