package js;

import Date in HaxeDate;
import js.jquery.Helper.*;
import js.jquery.JQuery;
import webmaniabr.*;
using StringTools;

@:keep @:expose
class CardReq
{
	public static function init()
	{
		new JQuery('document').ready(function(_){
			untyped $.fn.form.settings.rules.validaCPF = function(val){
				return MainJS.validaCPF(val);
			}
			untyped $.fn.form.settings.rules.date = function(val){
				var d : Date = null;
				try{
					d = parseDate(val);
				}
				catch(e : Dynamic)
				{}

				return d != null;
			}

			untyped $('select').dropdown();

			validate();

			new JQuery('#CEP').keyup(function(_){
                
				var cur = js.jquery.Helper.JTHIS;
                
				if(cur.val().length != 9)
					return;

				var api = new Correios("PxQtu0NJd0v6B2sPBUR0leTE8Eryi1ZN", "KffqAXnZIz6Wmb9pYWYkCFag0qHw1z4jsKHeKw3IpKF39Qur");
				api.queryCep(cur.val(), response);
				new JQuery('#loader').addClass('active');

			});

			// hide/disable UF selector (and replace with input) if the document type is not RG
			var ufSelector = null;
			J("#tpdoc").change(function (e) {
				if (J(e.target).val() != "0") {
					// hack: remote the parent div that's added by semantic ui
					var div = J('select[name="UFOrgao"]').parent("div").replaceWith('<input type="text" name="UFOrgao" autocomplete="lbelcard-uforgao" required>');
					ufSelector = {
						parent: div,
						label: J('label[for="UFOrgao"]').text()
					};
					// hack: reinstall the form validation
					validate();

					J('label[for="UFOrgao"]').text("estado/província emissora");
				} else if (ufSelector != null) {
					var stored = ufSelector;
					var select = stored.parent.children("select");
					J('input[name="UFOrgao"]').replaceWith(select);
					ufSelector = null;

					J('label[for="UFOrgao"]').text(stored.label);
					// hack: apply the necessary classes to prevent bad rendering
					select.attr("class", "ui fluid dropdown search");
					// hack: reinitialize the semantic ui dropdown
					untyped select.dropdown();
					// hack: reset the form validation
					validate();
					select.change();
				}
			});

			untyped $('#CPF').mask('000.000.000-00', {reverse : true});
			untyped $('#CEP').mask('00000-000');
			untyped $('#cel').mask('00000-0000');  // FIXME only if DDI == 55, if that
			untyped $('#DtNascimento').mask('00/00/0000');
			untyped $('#DtExpedicao').mask('00/00/0000');

			storage();
		});
	}

	static function storage()
	{
		var sess_storage = js.Browser.getSessionStorage();

		if(sess_storage != null &&
				sess_storage.key(0) != null &&
				sess_storage.key(0) != "")
		{
			for(i in 0...sess_storage.length)
			{
				var k = sess_storage.key(i);
				var val = sess_storage.getItem(k);

				if(val == null || val.length == 0)
					continue;

				if(k.startsWith("sel|"))
				{
					k = k.substr(4);
					untyped $('select[name="$k"]').dropdown('set selected', val);
				}
				else
				{
					var elem = new JQuery('input[name="${k}"]');
					elem.val(val);
				}
			}
		}

		//save stuff on form submit
		new JQuery('form').submit(function(_)
				{
					if(sess_storage == null)
						return;

					var sess_storage = js.Browser.getSessionStorage();
					if(sess_storage == null)
						return;

					new JQuery('input').each(function(i,elem)
							{
								var cur = new JQuery(elem);
								sess_storage.setItem(cur.attr('name'), cur.val());
							});
					new JQuery('select').each(function(i,elem)
					{
						var cur = new JQuery(elem);
						sess_storage.setItem('sel|${cur.attr("name")}', cur.val());
					});
				});
	}

	static function parseDate(text:String):HaxeDate
	{
		var emsg = 'Invalid date <$text>';
		var pat = ~/^\s*((\d\d)\/(\d\d)\/(\d\d\d\d))\s*$/;
		if (!pat.match(text))
			throw '$emsg: expected <DD/MM/YYYY>';
		var year = Std.parseInt(pat.matched(4));
		var month = Std.parseInt(pat.matched(3));
		var day = Std.parseInt(pat.matched(2));
		var now = HaxeDate.now();
		var computed =
			switch [year, month, day] {
			case [year, _, _] if (year < 1900 || year > now.getFullYear()):
				throw '$emsg: expected year to be between 1900 and ${now.getFullYear()}';
			case [_, month, _] if (month < 1 || month > 12):
				throw '$emsg: expected month to be between 01 and 12';
			case [_, _, day] if (day < 1 || day > 31):
				throw '$emsg: expected day to be between 01 and 31';
			case [year , 2, 29] if (year%4 != 0 || (year%100 == 0 && year%400 != 0)):
				throw '$emsg: $year is not a leap year';
			case [_, 4|6|9|11, 31], [_, 2, 30|31]:
				throw '$emsg: there is no ${pat.matched(1)} (day incompatible with month)';
			case _:
				new HaxeDate(year, month - 1, day, 0, 0, 0);
			};
		if (DateTools.format(computed, "%d/%m/%Y") != pat.matched(1))
			throw 'Assert failed: ${pat.matched(1)} => $computed';
		return computed;
	}

	static function response (d : Correios.Response<Correios.Address>)
	{
		new JQuery('#loader').removeClass('active');
		switch(d)
		{
		case Some(addr):
			var complexUf = ~/^([A-Z][A-Z]) - .+$/;
			if (complexUf.match(addr.uf)) {
				var simplified = complexUf.matched(1);
				show(addr.uf, simplified);
				addr.uf = simplified;
			}
			new JQuery('#uf').val(addr.uf);
			new JQuery('#cidade').val(addr.cidade);
			new JQuery('#bairro').val(addr.bairro);
			new JQuery('#logradouro').val(addr.endereco);

			var doctype = J("#tpdoc option:selected");
			if (doctype.val() == "0" && J("#docnum").val() == "") {
				var selector = J("#ufemissor");
				var uf = selector.find('option[value="${addr.uf}"]');
				weakAssert(uf.length == 1, addr.uf);
				uf.detach();
				selector.prepend(uf);
				selector.val(addr.uf).change();
			}
		case None:
			// FIXME ??
			js.Browser.alert('CEP inválido; por favor, verifique se o número está correto');
		case Failure(e):
			trace('error @webmania : $e');
		}
	}

	public static function onSubmit()
	{
		new JQuery('form').submit();
	}

	static function validate()
	{
		untyped $('.ui.form').form({
			'inline' : true,
			on : 'blur',
			fields : {
				NomeCompleto : {
					rules : [{
						type : 'empty',
						prompt : 'Digite seu nome completo, sem abreviações'
					}]
				},
				TpSexo : {
					rules : [{
						type : 'empty',
						prompt : 'Selecione uma opção'
					}]
				},
				DtNascimento : {
					rules : [{
						type : 'empty',
						prompt : 'Selecione a data de nascimento'
					},
					{
						type : 'date',
						prompt : 'Digite uma data válida'
					}]
				},
				NomePai : {
					rules : [{
						type : 'empty',
						prompt : 'Digite o nome completo de seu pai, sem abreviações'
					}]
				},
				NomeMae : {
					rules : [{
						type : 'empty',
						prompt : 'Digite o nome completo de sua mãe, sem abreviações'
					}]
				},
				DDI : {
					rules : [{
						type : 'empty',
						prompt : 'Digite o DDI to telefone informado'
					}]
				},
				DDD : {
					rules : [{
						type : 'empty',
						prompt : 'Digite o DDD do telefone informado'
					},
					{
						type : 'exactLength[2]',  // FIXME only if DDI == 55
						prompt : 'DDD inválido, ele só deve possuir 2 dígitos'
					}]
				},
				NumeroTel : {
					rules : [{
						type : 'empty',
						prompt : 'Digite o número de telefone'
					}]
				},
				TpTelefone : {
					rules : [{
						type : 'empty',
						prompt : 'Selecione o tipo de telefone'
					}]
				},
				CEP : {
					rules : [{
						type : 'exactLength[9]',
						prompt : 'CEP inválido'
					}]
				},
				UF : {
					rules : [{
						type : 'empty',
						prompt : 'Preencha o estado'
					}]
				},
				Cidade : {
					rules : [{
						type : 'empty',
						prompt : 'Preencha a cidade'
					}]
				},
				Bairro : {
					rules : [{
						type : 'empty',
						prompt : 'Preencha o bairro'
					}]
				},
				Logradouro : {
					rules : [{
						type : 'empty',
						prompt : 'Preencha o logradouro (rua, avenida, etc.)'
					}]
				},
				NumeroEnd : {
					rules : [{
						type : 'empty',
						prompt : 'Preencha o número no logradouro (ou informe "s/n")'
					}]
				},
				// skipping Complemento, it can be anything, really
				TpEndereco : {
					rules : [{
						type : 'empty',
						prompt : 'Informe o tipo do endereço'
					}]
				},
				Email : {
					rules : [{
						type : 'empty',
						prompt : 'Digite seu email de contato'
					}
									,{
										type : 'email',
										prompt : 'Digite um email válido'
									}]
				},
				CodCliente : {
					rules : [{
						type : 'empty',
						prompt : 'Digite seu CPF'
					},
					{
						type: 'exactLength[14]',
						prompt : 'Por favor, preencha com os 11 dígitos'
					},
					{
						type : 'validaCPF',
						prompt : 'CPF inválido'
					}]
				},
				NumDocumento : {
					rules : [{
						type : 'empty',
						prompt : 'Digite o número de documento'
					},
					{
						type : 'regExp[/[a-zA-Z0-9]+/g]',
						prompt : 'Digite apenas números e letras'
					}]
				},
				DtExpedicao : {
					rules : [{
						type : 'empty',
						prompt : 'Digite a data de expedição do documento'
					},
					{
						type : 'date',
						prompt : 'Digite uma data válida'
					}]
				},
				TpDocumento : {
					rules : [{
						type : 'empty',
						prompt : 'Preencha o tipo do documento informado'
					}]
				},
				OrgaoExpedidor : {
					rules : [{
						type : 'empty',
						prompt : 'Preencha a sigla do órgão expedidor'
					}]
				},
				UFOrgao : {
					rules : [{
						type : 'empty',
						prompt : 'Preencha o local (estado, província, etc.) onde o documento foi emitido'
					}]
				},
				PaisOrgao : {
					rules : [{
						type : 'empty',
						prompt : 'Preencha o país onde o documento foi emitido'
					}]
				}
			}
		});
	}
}
