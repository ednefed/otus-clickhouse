#!/usr/bin/env bash

set -o errexit

while read -r input; do
	quantity=${input%%,*}
	price=${input#*,}
	threshold=600000000

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
	# Переведём пороговое значение в копейки
	threshold_cents=$(( threshold * 100 ))

	# Сравним
	if [[ $total_cents -gt $threshold_cents ]]; then
		result="wow"
	else
		result="meh"
	fi

	printf "%s\n" "$result"
done
