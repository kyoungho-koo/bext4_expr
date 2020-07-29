RET1=`awk 'BEGIN{ RS = "" ; FS = "\n" }{print $1,$10,$11}' $1 | awk '{print $1,$10,$14}'`
RET2=`grep -E " ops/s" $2 | awk '{print $6}'`

echo $3 $RET1 $RET2

