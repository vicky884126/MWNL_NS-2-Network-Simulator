BEGIN {
		init = 0;
		i = 0;
}
{
		action = $1;
		time = $2;
		pkttype= $7
		pktsize = $8;
	if (action == "r") {
 		pkt_byte_sum[i + 1] = pkt_byte_sum[i] + pktsize;
			if (init == 0) {
				start_time = time;
				init = 1;
			}
			end_time[i] = time;
			i = i + 1;
		}
}
END {
		printf("%.2f\t%.2f\n", end_time[0], 0);
		for (j = 1 ; j < i ; j++) {
			if (end_time[j] != start_time) {
				th = pkt_byte_sum[j] / (end_time[j] - start_time)*8*0.001;
				printf("%.2f\t%.2f\n", end_time[j], th);
			}
		}
}
