# mikrotik

# dual-dinamic-pppoe-ipv6-v6-com-netwatch-pub.rsc

Script criado para dual wan/failover usado em uma RB 750gr3 Hex para as operadoras VIVO (modo pppoe / PPPoe client) e VIRTUA (modo bridge / DHCP client), com uso de IPv4 e IPv6 (prefix delegation).

Link VIVO como principal e VIRTUA como backup/standby.

Scripts de dual wan/failover para IPv4 sao bem comuns - mas para IPv6 nem tanto.

Qual a dificuldade de dual wan em IPv6 ?

O failover em IPv4 sempre eh feito via NAT, as estacoes possuem IP privado e sao roteadas via MASQUERADE/SRCNAT como IP publico do firewall, apenas com a rota de saida variando conforme o link que estiver ativo - nenhum problema maior aqui.

Em IPv6, por outro lado, a ideia eh NAO USAR NAT - entao as estacoes vao receber um IP publico valido, e a RB MIKROTIK faz apenas o papel de firewall do trafego que pode entrar/sair para as estacoes.

Uma alternativa eh a estacao receber o IPv6 via RA de todas as operadoras - mas gera algums problemas:
1) Caso queira criar um DDNS IPv6 direto para um servico da estacao, como a estacao tem multiplos IPv6 (p.ex. 1 da VIVO e 1 da VIRTUA), o controle eh complexo (p.ex. a estacao saber qual o link principal para atualizacao DDNS ou entao criar multiplas entradas DDNS AAAA para cada operadora, mas com o problema de gerenciar a adicao/remocao destes registros DDNS conforme o status de cada link).
2) O controle da rota default (link principal) da estacao tambem tem complexidades.

Para fugir do uso de NAT/ULA/Multiplos IPv6 na estacao - o script usa a seguinte solucao: apenas 1 IPv6 client ficara ativo, relativo ao link/operadora em uso.

Assim, se o link principal for o VIVO (que eh o default) - a estacao recebe o IPv6 deste link.

Atraves do monitoramento feito via 'netwatch', caso o link VIVO caia, eh executado o comando 'down-script', que desativa o IPv6 client da VIVO e ativa o IPv6 client da VIRTUA, forcando assim um novo RA para as estacoes.

Este monitoramento continua ativo - e caso o link VIVO retorne, eh executado o comando 'up-script', que desativa o IPv6 client da VIRTUA e ativa o IPv6 client da VIVO, forcando um novo RA para as estacoes.

Nao eh uma solucao 'bonita', mas funciona dentro dos objetivos pretendidos (cada estacao ter apenas um IPv6 publico ativo).

A tentacao de usar IPv6 com NAT eh grande (NAT66) - mas esbarra no fato das RB MIKROTIK ainda nao terem suporte a esta feature (prometida para a versao 7 do RouterOS).
